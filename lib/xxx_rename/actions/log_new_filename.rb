# frozen_string_literal: true

require "xxx_rename/actions/base_action"

module XxxRename
  module Actions
    class LogNewFilename < BaseAction
      def perform(_dir, file, search_result)
        new_filename = FilenameGenerator.generate_with_multi_formats!(
          search_result.scene_data,
          File.extname(file),
          config.prefix_hash,
          *output_patterns(search_result.site_client)
        )

        XxxRename.logger.info "[RENAME OPERATION]".colorize(:blue)
        XxxRename.logger.info "\t#{"ORIGINAL:".colorize(:light_magenta)} #{file}"
        XxxRename.logger.info "\t#{"NEW:     ".colorize(:green)} #{new_filename}"

        config.output_recorder.create!(search_result.scene_data, file, new_filename, Dir.pwd)
      rescue FilenameGenerationError => e
        XxxRename.logger.error "#{"[RENAME OPERATION ERROR]".colorize(:red)} #{e.message}"
        nil
      rescue Contract::FileRenameOpValidationFailure => e
        XxxRename.logger.error "[RENAME OPERATION VALIDATION ERROR] #{e.message}"
        nil
      end

      #
      # Return a list of patterns that will be used to generate the new filename
      # Individual site client formats take precedence over global formats
      #
      # @param [XxxRename::SiteClients::Base] site_client
      # @return [Array[String]]
      def output_patterns(site_client)
        site_client.site_config.output_format.push(*config.global.output_format)
      end
    end
  end
end
