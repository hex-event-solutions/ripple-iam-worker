# frozen_string_literal: true

module RippleWorker
  class Validate
    class << self
      def validate(required_params, body)
        missing_params = required_params - body.keys
        raise "Missing required params #{missing_params}" if missing_params.any?

        true
      end
    end
  end
end
