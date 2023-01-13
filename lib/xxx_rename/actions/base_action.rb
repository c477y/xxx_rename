# frozen_string_literal: true

module XxxRename
  module Actions
    class BaseAction
      attr_reader :config

      def initialize(config)
        @config = config
      end

      # @param [String] _dir
      # @param [String] _file
      # @param [XxxRename::Search::SearchResult] _search_result
      def perform(_dir, _file, _search_result)
        raise "Not Implemented"
      end
    end
  end
end
