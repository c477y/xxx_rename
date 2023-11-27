# frozen_string_literal: true

module XxxRename
  module Actions
    class BaseAction
      # @param [String] _dir
      # @param [String] _file
      # @param [Search::SearchResult] _search_result
      def perform(_dir, _file, _search_result)
        raise "Not Implemented"
      end

      def config
        XxxRename.config
      end
    end
  end
end
