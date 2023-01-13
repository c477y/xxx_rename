# frozen_string_literal: true

require "yaml/store"

require "xxx_rename/data/query_interface"
require "xxx_rename/contract/file_rename_op_contract"
require "xxx_rename/data/file_rename_op"

module XxxRename
  module Data
    OUTPUT_KEY = "___RENAME_ACTIONS___"
    STATUS_KEY = "___MIGRATION_STATUS___"
    FAILURES_KEY = "___FAILURES___"

    class OutputDatastore
      attr_reader :store

      OUTPUT = "output"

      def initialize(dir)
        file = "#{OUTPUT}_#{Time.now.strftime("%Y%m%d%H%M")}.yml"

        Dir.chdir(dir) { FileUtils.mkdir OUTPUT unless Dir.exist?(OUTPUT) }

        path = File.join(dir, OUTPUT, file)
        @store = YAML::Store.new path
        XxxRename.logger.info "Output will be recorded in #{file}"
      end
    end

    class FileRenameOpDatastore < QueryInterface
      def create!(scene_data, source_file, output_file, dir = Dir.pwd)
        hash = {
          key: scene_data.key,
          directory: dir,
          source_filename: source_file,
          output_filename: output_file,
          mtime: scene_data.date_released
        }
        data = make_file_rename_op!(hash)
        semaphore.synchronize do
          store.transaction do
            store[OUTPUT_KEY] ||= []
            store[OUTPUT_KEY] << data
          end
        end
      end

      def length
        semaphore.synchronize do
          store.transaction(true) do
            store.fetch(OUTPUT_KEY, []).length
          end
        end
      end

      def all
        semaphore.synchronize do
          store.transaction(true) do
            store.fetch(OUTPUT_KEY, [])
          end
        end
      end

      def failures
        semaphore.synchronize do
          store.transaction(true) do
            store.fetch(FAILURES_KEY, {})
          end
        end
      end

      def add_failure(key, error)
        semaphore.synchronize do
          store.transaction do
            store[FAILURES_KEY] ||= {}
            store[FAILURES_KEY][key] = error
          end
        end
      end

      def migration_status
        semaphore.synchronize do
          store.transaction(true) do
            val = store.fetch(STATUS_KEY, 0)
            val == 1
          end
        end
      end

      def migration_status=(status)
        semaphore.synchronize do
          store.transaction do
            store[STATUS_KEY] = status
          end
        end
      end

      private

      def make_file_rename_op!(hash)
        contract = Contract::FileRenameOpContract.new.call(hash)

        raise Contract::FileRenameOpValidationFailure, contract.errors.to_h unless contract.errors.empty?

        valid_hash = contract.to_h.transform_keys(&:to_s)
        FileRenameOp.new(valid_hash)
      end
    end
  end
end
