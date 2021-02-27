# frozen_string_literal: true

module XxxRename
  module SceneByFile
    class RealityKings < Base
      def initialize
        super("https://www.realitykings.com/home")
      end

      def create_file_name(hsh, file)
        XxxRename::Utils.gen_filename(hsh, file)
      end
    end
  end
end
