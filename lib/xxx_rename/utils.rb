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

      def already_processed?(filename)
        basename = File.basename(filename)
        basename.match(/.*(\[F\]){1}.*(\[M\])*.*/)
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
        file_name.gsub(%r{[.\x00/\\:*?!"<>|']}, "").strip + File.extname(file)
      end

      def scene_title(file)
        basename = File.basename(file, ".*")
        if basename.match(/[\w-]*_\d{3,4}p/)
          # Scene is downloaded from the site and not processed
          scene_title_arr = File.basename(file, ".*").split("_").first.split("-")
          XxxRename::Utils.adjust_apostrophe(scene_title_arr)
        elsif basename.match(/.*(\[F\]){1}.*(\[M\])*.*/)
          # Scene is processed by the application. Get the title
          XxxRename::ProcessedFile.new(basename).title
          # Brazzers\ Exxtra\ -T-\ Sex\ With\ The\ Ex\ -F-\ Holly\ Hotwife\ -M-\ Keiran\ Lee.mp4
        elsif basename.match(/.*(-T-){1}.*(-F-){1}.*(-F-)*.*/)
          basename.split("-T-").last.split("-F-").first.strip
        else
          # Search with the filename as is. This means the file may be downloaded
          # from some other source. In such a case, make sure that the file
          # name is the exact name of the scene
          basename
        end
      end

      def site_client(site)
        case site
        when "bz"
          XxxRename::SceneByFile::Brazzers.new
        when "dp"
          XxxRename::SceneByFile::DigitalPlayground.new
        when "rk"
          XxxRename::SceneByFile::RealityKings.new
        when "bb"
          XxxRename::SceneByFile::Babes.new
        else
          raise "invalid site name #{@site}"
        end
      end

      def action_mapper(obj, action)
        case action
        when "set_scene_date"
          proc { |hash, file, opt| obj.modify_date_action(hash, file, **opt) }
        when "verbose"
          proc { |hash, file, opt| obj.verbose_action(hash, file, **opt) }
        else
          raise "Invalid action #{action}"
        end
      end
    end
  end
end
