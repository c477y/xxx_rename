# frozen_string_literal: true

require "xxx_rename/file_utilities"

module XxxRename
  module Data
    class FileRenameOp < Base
      include FileUtilities

      attribute :key, Types::String
      attribute :directory, Types::String
      attribute :source_filename, Types::String
      attribute :output_filename, Types::String
      attribute :mtime, Types::Time.optional

      def rename
        Dir.chdir(directory) do
          File.rename(source_filename, output_filename)

          # This has been deprecated in favour of storing timestamps in filename
          # File.utime(File.atime(output_filename), mtime, output_filename) if mtime

          XxxRename.logger.info "[RENAME COMPLETE]".colorize(:blue)
          XxxRename.logger.info "\t#{"WAS:".colorize(:light_magenta)} #{source_filename}"
          XxxRename.logger.info "\t#{"NOW:".colorize(:green)} #{output_filename}"
          true
        end
      end

      def reverse_rename
        Dir.chdir(directory) do
          File.rename(output_filename, source_filename)

          XxxRename.logger.info "[RENAME ROLLBACK COMPLETE]".colorize(:blue)
          XxxRename.logger.info "\t#{"WAS:".colorize(:light_magenta)} #{output_filename}"
          XxxRename.logger.info "\t#{"NOW:".colorize(:green)} #{source_filename}"
          true
        end
      end
    end
  end
end
