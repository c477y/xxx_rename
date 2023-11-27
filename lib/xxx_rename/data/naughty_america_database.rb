# frozen_string_literal: true

module XxxRename
  module Data
    class NaughtyAmericaDatabase
      attr_reader :store

      DEFAULT_STORE_FILE = "naughtyamerica.store"

      def initialize(store_file)
        store_file = DEFAULT_STORE_FILE if store_file.nil?

        path = File.join(Dir.pwd, store_file)
        XxxRename.logger.info "[DATABASE INITIALISATION] #{path}"

        @store = PStore.new path
      end
    end
  end
end
