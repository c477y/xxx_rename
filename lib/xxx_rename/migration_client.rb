# frozen_string_literal: true

require "active_support/core_ext/object/try"
require "yaml/store"

require "xxx_rename/errors"
require "xxx_rename/data/file_rename_op"
require "xxx_rename/data/file_rename_op_datastore"

module XxxRename
  class MigrationClient
    MIGRATION_FORMAT = /output_(?<version>\d{12})/x.freeze

    attr_reader :config, :version

    # @param [XxxRename::Data::Config] config
    # @param [String] version
    def initialize(config, version)
      @version = version
      @config = config
    end

    def version_file!
      Dir.chdir(output_dir) do
        all_output_files = Dir["output_*.yml"].sort.reverse!
        raise Errors::FatalError, "[ERR NO MIGRATION FILES FOUND]" if all_output_files.empty?

        file = match_file!(all_output_files)
        File.join(Dir.pwd, file)
      end
    end

    def datastore
      @datastore ||= Data::FileRenameOpDatastore.new(store, config.mutex)
    end

    def apply
      if datastore.migration_status
        XxxRename.logger.info "[MIGRATION UP]"
        return
      end

      XxxRename.logger.info "[RENAMING #{datastore.length} FILES]"
      datastore.all.each do |op|
        process_rename_op(op)
      rescue SystemCallError => e
        XxxRename.logger.error "[RENAME FAILURE] #{e.message}"
        datastore.add_failure(op.key, e.message)
      end
    ensure
      if datastore.failures.empty?
        datastore.migration_status = 1
        XxxRename.logger.info "[MIGRATION UP]"
      end
    end

    def rollback
      unless datastore.migration_status
        XxxRename.logger.info "[MIGRATION DOWN]"
        return
      end

      XxxRename.logger.info "[ROLLBACK RENAMING #{datastore.length} FILES]"
      datastore.all.each do |op|
        process_reverse_rename_op(op)
      rescue SystemCallError => e
        XxxRename.logger.error "[RENAME FAILURE] #{e.message}"
        datastore.add_failure(op.key, e.message)
      end
    ensure
      if datastore.failures.empty?
        datastore.migration_status = 0
        XxxRename.logger.info "[MIGRATION DOWN]"
      end
    end

    private

    def match_file!(all_output_files)
      if version.downcase == "latest"
        all_output_files.first
      else
        matched_file = all_output_files.select do |x|
          match = x.match(MIGRATION_FORMAT)
          next if match.nil?

          match[:version] == version
        end.compact.first
        raise Errors::FatalError, "[ERR VERSION NOT EXIST] #{version}" if matched_file.nil?

        matched_file
      end
    end

    def process_rename_op(rename_op)
      if rename_op.is_a?(XxxRename::Data::FileRenameOp)
        rename_op.rename
        register_new_file(rename_op)
      else
        XxxRename.logger.error "[INVALID RENAME OP] #{rename_op}"
      end
    end

    def register_new_file(rename_op)
      scene_data = config.scene_datastore.find_by_key?(rename_op.key)
      return if scene_data.nil?

      config.scene_datastore.register_file(scene_data,
                                           File.join(rename_op.directory, rename_op.output_filename),
                                           old_filename: File.join(rename_op.directory, rename_op.source_filename))
    end

    def process_reverse_rename_op(rename_op)
      if rename_op.is_a?(XxxRename::Data::FileRenameOp)
        rename_op.reverse_rename
        register_old_filename(rename_op)
      else
        XxxRename.logger.error "[INVALID RENAME OP] #{rename_op}"
      end
    end

    def register_old_filename(rename_op)
      scene_data = config.scene_datastore.find_by_key?(rename_op.key)
      return if scene_data.nil?

      config.scene_datastore.register_file(scene_data,
                                           File.join(rename_op.directory, rename_op.source_filename),
                                           old_filename: File.join(rename_op.directory, rename_op.output_filename))
    end

    def store
      @store ||= YAML::Store.new(version_file!)
    end

    def output_dir
      @output_dir ||= File.join(config.generated_files_dir, "output")
    end
  end
end
