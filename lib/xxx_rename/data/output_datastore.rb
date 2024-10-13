# frozen_string_literal: true

require "yaml/store"

module XxxRename
  module Data
    class OutputDatastore
      attr_reader :store

      OUTPUT = "output"

      def initialize(dir)
        file = "#{OUTPUT}_#{Time.now.strftime("%Y%m%d%H%M")}.yml"

        Dir.chdir(dir) { FileUtils.mkdir OUTPUT unless Dir.exist?(OUTPUT) }

        path = File.join(dir, OUTPUT, file)
        @store = YAML::Store.new path
        XxxRename.logger.info "[OUTPUT FILE CREATED] #{file}"
      end
    end
  end
end
