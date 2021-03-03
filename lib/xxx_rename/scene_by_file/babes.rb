# frozen_string_literal: true

module XxxRename
  module SceneByFile
    class Babes < Base
      def initialize
        super("https://www.babes.com/home")
      end

      def create_file_name(hsh, file)
        XxxRename::Utils.gen_filename(hsh, file)
      end
    end
  end
end
