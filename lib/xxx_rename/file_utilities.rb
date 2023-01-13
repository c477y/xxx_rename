# frozen_string_literal: true

module XxxRename
  module FileUtilities
    MAX_FILENAME_LEN = 255

    def valid_file?(file)
      file && File.exist?(file) && File.file?(file)
    end

    def valid_dir?(dir)
      dir && File.exist?(dir) && File.directory?(dir)
    end

    def read_file!(file)
      return File.read(file).strip if valid_file?(file)

      raise Errors::FatalError, "Unable to read file #{file}"
    end

    def read_yaml(file, default = {}, validate_type = nil)
      read_yaml!(file, validate_type)
    rescue Errors::FatalError
      default
    end

    def read_yaml!(file, validate_type)
      raise Errors::FatalError, "Unable to read yaml file #{file}" unless file && File.file?(file) && File.exist?(file)

      yaml = YAML.load_file(file)
      return yaml unless validate_type

      return yaml if yaml.is_a?(validate_type)

      raise Errors::FatalError, "#{file}: Invalid YAML contents. Was expecting #{validate_type}, but received #{yaml.class}"
    end
  end
end
