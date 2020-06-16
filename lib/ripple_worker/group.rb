module RippleWorker
  class Group
    class << self
      def create(body)
        RippleWorker::Validate.validate([:name], body)

        response = RippleKeycloak::Group.create(body)

        puts "Created group #{response} from #{body}"
      end
    end
  end
end
