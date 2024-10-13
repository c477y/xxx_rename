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

    class ParsingError < StandardError
      attr_reader :str, :regex

      def initialize(str, regex)
        @str = str
        @regex = regex
        super(message)
      end

      def message
        "String \"#{str}\" does not match regex /#{regex}/"
      end
    end

    class FatalError < StandardError; end
    class UnprocessedEntity < StandardError; end

    class StashAPIError < StandardError
      def initialize(errors)
        @errors = errors
        super(message)
      end

      def message
        msg = "Stash API returned error:\n"
        @errors.each do |e|
          s  = "\tMESSAGE #{e["message"]}\n"
          s += "\tOPERATION #{e["path"]} \n"
          msg += s
        end
        msg
      end
    end
  end
end
