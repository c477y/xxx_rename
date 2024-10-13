# frozen_string_literal: true

module XxxRename
  module Data
    DEFAULT_STORE_FILE = "xxx_rename_datastore.store"

    class SceneDatastore
      attr_reader :store

      def initialize(dir, name = DEFAULT_STORE_FILE)
        path = File.join(dir, name)
        XxxRename.logger.debug "#{"[DATASTORE INIT]".colorize(:green)} #{path} #{name}"

        @store = PStore.new path
      end
    end
  end
end
