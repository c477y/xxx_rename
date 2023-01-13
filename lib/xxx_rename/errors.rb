# frozen_string_literal: true

module XxxRename
  module Errors
    class SafeExit < StandardError; end

    class ConfigValidationError < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(message)
      end

      def message
        messages = []
        errors.messages.each do |key|
          messages << "#{key.path.join(".")}: #{key.text}"
        end
        messages.join(", ")
      end
    end

    class ParsingError < StandardError; end
    class FatalError < StandardError; end
    class UnprocessedEntity < StandardError; end
  end
end
