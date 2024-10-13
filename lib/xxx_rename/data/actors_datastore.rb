# frozen_string_literal: true

module XxxRename
  module Data
    ACTORS_DATASTORE_DEFAULT_STORE_FILE = "xxx_rename_actors_datastore.store"

    class ActorsDatastore
      attr_reader :store

      def initialize(dir, name = ACTORS_DATASTORE_DEFAULT_STORE_FILE)
        path = File.join(dir, name)
        XxxRename.logger.debug "[DATASTORE INIT] #{path} #{name}"

        @store = PStore.new path
      end
    end
  end
end
