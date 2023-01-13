# frozen_string_literal: true

require "xxx_rename/actions/log_new_filename"
require "xxx_rename/actions/stash_app_post_movie"

module XxxRename
  module Actions
    class Resolver
      def initialize(config)
        @config = config
      end

      def resolve!(action)
        action = action.to_sym
        case action
        when :sync_to_stash
          actions_klass_hash.fetch(action, StashAppPostMovie.new(@config))
        when :log_rename_op
          actions_klass_hash.fetch(action, LogNewFilename.new(@config))
        else
          raise Errors::FatalError, "Unknown action #{action}"
        end
      end

      private

      def actions_klass_hash
        @actions_klass_hash ||= {}
      end
    end
  end
end
