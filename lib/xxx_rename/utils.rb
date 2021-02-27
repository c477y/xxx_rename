# frozen_string_literal: true

module XxxRename
  class Utils
    class << self
      # Remove the following characters from the input string and returns
      # it in lower case
      #
      # \s : whitespace characters
      # \W : any non-word character
      # _  : underscore
      #
      def normalize(str)
        str.gsub(/[\s\W_]/, "").downcase
      end

      # Accept an array of strings which make up the scene name
      # The function returns a string where the elements which make
      # up one word are joined together.
      #
      def adjust_apostrophe(arr)
        # Convert the hyphen to spaces for easier searching
        apostrophe_chars = %w[t s d ve ll re m]
        resp = []
        arr.each_with_index do |e, i|
          next if apostrophe_chars.include? e

          resp << if apostrophe_chars.include? arr[i + 1]
                    [e, arr[i + 1]].join("'")
                  else
                    e
                  end
        end
        resp.join(" ")
      end

      # Gets the scene name from a given file name
      # Acceptable scene name format is `scene-name_resolution.*`
      # This method will remove the extension and the resolution and return
      # the remaining part
      #
      # Input should be a valid file
      def scene_name(filename)
        File.basename(filename, ".*").split("_").first.to_s
      end

      def already_processed?(filename)
        filename.include?("[F]")
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
      def gen_filename(hsh, file)
        file_name = ""
        file_name += "#{hsh[:title]} "
        file_name += "[F] #{hsh[:female_actors].join(", ")} "
        # Add male actors only if the file name has not exceeded 150 characters
        # This is done to handle cases where the filename can become too big and result in errors
        file_name += "[M] #{hsh[:male_actors].join(", ")}" if file_name.length < 150 && !hsh[:male_actors].empty?
        file_name.gsub(%r{[.\x00/\\:*?!"<>|']}, "") + File.extname(file)
      end
    end
  end
end
