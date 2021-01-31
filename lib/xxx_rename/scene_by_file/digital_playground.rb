# frozen_string_literal: true

module XxxRename
  module SceneByFile
    class DigitalPlayground < Base
      def initialize
        super("https://www.digitalplayground.com/home")
      end

      # Remove the following characters from the generated file name:
      #
      # . (dot)
      # U+0000 (NUL)
      # / (slash)
      # \ (backslash)
      # : (colon)
      # * (asterisk)
      # ? (question mark)
      # " (quote)
      # < (less than)
      # > (greater than)
      # | (pipe)
      #
      def create_file_name(hsh, file)
        file_name = ""
        file_name += "#{hsh[:title]} "
        file_name += "[F] #{hsh[:female_actors].join(", ")} "
        file_name += "[M] #{hsh[:male_actors].join(", ")}" unless hsh[:male_actors].empty?
        file_name.gsub(%r{[.\x00/\\:*?!"<>|]}, "") + File.extname(file)
      end
    end
  end
end
