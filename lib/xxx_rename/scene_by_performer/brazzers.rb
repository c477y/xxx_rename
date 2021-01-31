# frozen_string_literal: true

module XxxRename
  module SceneByPerformer
    class Brazzers < Base
      def initialize
        super("https://www.brazzers.com/home")
      end

      def create_file_name(hsh, file)
        file_name = ""
        file_name += "#{hsh[:title]} "
        file_name += "[C] #{hsh[:collection]} " unless hsh[:collection].nil?
        file_name += "[F] #{hsh[:female_actors].join(", ")} "
        file_name += "[M] #{hsh[:male_actors].join(", ")}" unless hsh[:male_actors].empty?
        file_name.gsub(%r{[.\x00/\\:*?!"<>|]}, "") + File.extname(file)
      end
    end
  end
end
