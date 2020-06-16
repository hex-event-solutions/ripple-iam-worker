module RippleWorker
  class User
    class << self
      def create(body)
        RippleWorker::Validate.validate(%i[email first_name last_name phone], body)

        response = RippleKeycloak::User.create(body)

        puts "Created user #{response} from #{body}"
      end

      def add_to_group(body)
        RippleWorker::Validate.validate(%i[user_id group_id], body)

        RippleKeycloak::User.add_to_group(body[:user_id], body[:group_id])

        puts "Added user #{body[:user_id]} to group #{body[:group_id]}"
      end

      def remove_from_group(body)
        RippleWorker::Validate.validate(%i[user_id group_id], body)

        RippleKeycloak::User.remove_from_group(body[:user_id], body[:group_id])

        puts "Removed user #{body[:user_id]} from group #{body[:group_id]}"
      end

      def add_role(body)
        RippleWorker::Validate.validate(%i[user_id role_name], body)

        RippleKeycloak::User.add_role(body[:user_id], body[:role_name])

        puts "Added role #{body[:role_name]} to user #{body[:user_id]}"
      end

      def remove_role(body)
        RippleWorker::Validate.validate(%i[user_id role_name], body)

        RippleKeycloak::User.remove_role(body[:user_id], body[:role_name])

        puts "Removed role #{body[:role_name]} from user #{body[:user_id]}"
      end
    end
  end
end
