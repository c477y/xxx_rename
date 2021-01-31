# frozen_string_literal: true

module XxxRename
  class Validator
    def self.validate_rename_input(obj, site)
      valid_sites = %w[bz dp]
      raise "Object should be a valid file or a valid directory" unless File.file?(obj) || File.directory?(obj)

      raise "Site is not valid. Acceptable values are: #{valid_sites}" unless valid_sites.include?(site)
    end

    def self.validate_rename_from_file(file)
      raise "File does not exist" unless File.file?(file)
    end

    def self.validate_dir(dir)
      raise "Not a directory." unless File.directory? dir
    end
  end
end
