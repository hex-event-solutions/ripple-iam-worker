# frozen_string_literal: true

module RippleWorker
  class Role
    class << self
      def create(**body)
        RippleWorker::Validate.validate([:name], body)

        response = RippleKeycloak::Role.create(**body)

        puts "Created role #{response} from #{body}"
      end
    end
  end
end
