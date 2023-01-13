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

    class FileRenameOpContract < Dry::Validation::Contract
      include FileUtilities

      schema do
        required(:key).value(:string)
        required(:directory).value(:string)
        required(:source_filename).filled(:string)
        required(:output_filename).filled(:string)
        required(:mtime).maybe(Types::Time)
      end

      rule(:directory) do
        key(:directory_not_exists).failure(value) unless valid_dir?(value)
        key(:non_absolute_path).failure(value) unless Pathname.new(value).absolute?
      end

      rule(:directory, :source_filename) do
        unless rule_error?(:directory_not_exists)
          path = File.join(values[:directory], values[:source_filename])
          key(:file_not_found).failure(path) unless valid_file?(path)
        end
      end

      rule(:output_filename) do
        key(:output_filename_too_long).failure(value) if value.length > MAX_FILENAME_LEN
      end

      rule(:directory, :output_filename) do
        unless rule_error?(:directory_not_exists)
          path = File.join(values[:directory], values[:output_filename])
          key(:output_file_already_exists).failure(path) if valid_file?(path)
        end
      end
    end
  end
end
