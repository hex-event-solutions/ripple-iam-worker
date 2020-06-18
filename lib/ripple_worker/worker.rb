# frozen_string_literal: true

require 'bunny'
require 'ripple_keycloak'
require 'json'

module RippleWorker
  class Worker
    attr_reader :bunny, :keycloak, :queue, :exchange

    def initialize
      init_bunny
      init_keycloak
      puts "#{queue_name} worker initialized"
    end

    def run
      puts 'Waiting for messages'

      begin
        queue.subscribe(manual_ack: true, block: true) do |delivery_info, props, body|
          body = JSON.parse(body, symbolize_names: true)
          object_type = extract_header props, 'object_type'
          action = extract_header props, 'action'

          if allowed_messages.key? object_type
            if allowed_messages[object_type].include? action
              begin
                process_message(object_type, action, body)
              rescue RippleKeycloak::NotFoundError => e
                Airbrake.notify(e)
                pp e
                republish_and_retry(props[:headers], body)
              rescue RippleKeycloak::Error => e
                Airbrake.notify(e)
                pp e
              end
            else
              puts 'No action'
            end
          else
            puts 'No object type'
          end

          channel.ack(delivery_info.delivery_tag)
        end
      end
    end

    private

    def republish_and_retry(headers, body)
      message_retry_count = headers['retry_count'].to_i || 0
      retry_count = ENV.fetch('RIPPLE_WORKER_MAX_RETRY', 5)
      exceeded_retry_count = message_retry_count >= retry_count
      if exceeded_retry_count
        Airbrake.notify(ExceededMaxRetryCountError.new([headers, body]))
        puts 'Exceeded retry count, not republishing'
      else
        puts 'Republishing message'
        headers['retry_count'] = (message_retry_count + 1).to_s
        exchange.publish(body.to_json, headers: headers)
      end
    end

    def channel
      @channel ||= @bunny.create_channel
    end

    def extract_header(properties, key)
      properties[:headers][key].to_sym
    end

    def process_message(object_type, action, body)
      puts "Processing message with object_type: #{object_type}, action: #{action}, body: #{body}"
      object_name = "RippleWorker::#{object_type.to_s.capitalize}"
      if class_exists?(object_name)
        process_or_notify(Object.const_get(object_name), action, body)
      else
        puts 'No operations defined for this object type'
      end
    end

    def process_or_notify(klass, action, body)
      if klass.respond_to? action
        klass.public_send(action, **body)
      else
        puts 'This operation is not defined for this object type'
      end
    end

    def class_exists?(constant)
      Object.const_get(constant)
    rescue StandardError
      false
    end

    def allowed_messages
      {
        group: %i[create add_role remove_role],
        user: %i[create add_role remove_role add_to_group remove_from_group],
        role: %i[create]
      }
    end

    def init_bunny
      @bunny = Bunny.new(
        hostname: ENV.fetch('RABBIT_HOSTNAME'),
        port: ENV.fetch('RABBIT_PORT'),
        user: ENV.fetch('RABBIT_USER'),
        password: ENV.fetch('RABBIT_PASSWORD')
      )
      @bunny.start
      init_queue
      init_exchange
      bind_queue
      channel.prefetch(1)
    end

    def init_queue
      @queue = channel.queue(
        queue_name,
        { durable: true, auto_delete: false }
      )
    end

    def init_exchange
      @exchange = channel.headers(ENV.fetch('RABBIT_EXCHANGE'), durable: true)
    end

    def queue_name
      "#{ENV.fetch('RABBIT_EXCHANGE')}.#{ENV.fetch('RABBIT_QUEUE')}"
    end

    def bind_queue
      case ENV.fetch('RABBIT_QUEUE')
      when 'groups'
        base_arg = { 'object_type' => 'group' }
        queue.bind(exchange, arguments: base_arg.merge({ 'action' => 'create' }))
        queue.bind(exchange, arguments: base_arg.merge({ 'action' => 'add_role' }))
        queue.bind(exchange, arguments: base_arg.merge({ 'action' => 'remove_role' }))
      when 'users'
        base_arg = { 'object_type' => 'user' }
        queue.bind(exchange, arguments: base_arg.merge({ 'action' => 'create' }))
        queue.bind(exchange, arguments: base_arg.merge({ 'action' => 'add_to_group' }))
        queue.bind(exchange, arguments: base_arg.merge({ 'action' => 'remove_from_group' }))
        queue.bind(exchange, arguments: base_arg.merge({ 'action' => 'add_role' }))
        queue.bind(exchange, arguments: base_arg.merge({ 'action' => 'remove_role' }))
      when 'roles'
        base_arg = { 'object_type' => 'role' }
        queue.bind(exchange, arguments: base_arg.merge({ 'action' => 'create' }))
      end
    end

    def init_keycloak
      RippleKeycloak::Client.configure do |c|
        c.base_url = ENV.fetch('KEYCLOAK_BASE_URL')
        c.realm = ENV.fetch('KEYCLOAK_REALM')
        c.client_id = ENV.fetch('KEYCLOAK_CLIENT_ID')
        c.client_secret = ENV.fetch('KEYCLOAK_CLIENT_SECRET')
      end
    end
  end
end
