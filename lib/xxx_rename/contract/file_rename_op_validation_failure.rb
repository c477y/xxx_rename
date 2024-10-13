# frozen_string_literal: true

module XxxRename
  module Contract
    class FileRenameOpValidationFailure < StandardError
      # @param [Hash] errors
      def initialize(errors)
        @errors = errors
        super(message)
      end

      def message
        ers = []
        @errors.each_pair { |code, value| ers << "#{code}: #{value.join(" ")}" }
        ers.join(", ")
      end
    end
  end
end
