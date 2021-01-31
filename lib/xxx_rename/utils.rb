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
    end
  end
end
