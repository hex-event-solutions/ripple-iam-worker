# frozen_string_literal: true

module RippleWorker
  class Group
    class << self
      def create(**body)
        RippleWorker::Validate.validate([:name], body)

        response = RippleKeycloak::Group.create(body)

        puts "Created group #{response} from #{body}"
      end

      def add_role(**body)
        RippleWorker::Validate.validate(%i[group_id role_name], body)

        RippleKeycloak::Group.add_role(body[:group_id], body[:role_name])

        puts "Added role #{body[:role_name]} to group #{body[:group_id]}"
      end

      def remove_role(**body)
        RippleWorker::Validate.validate(%i[group_id role_name], body)

        RippleKeycloak::Group.remove_role(body[:group_id], body[:role_name])

        puts "Removed role #{body[:role_name]} from group #{body[:group_id]}"
      end
    end
  end
end
