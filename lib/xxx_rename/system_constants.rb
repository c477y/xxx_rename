# frozen_string_literal: true

module XxxRename
  module SystemConstants
    def home_dir
      ENV["HOME"]
    end

    def config_file_lookup_dirs
      [
        File.join(home_dir, ".config", "xxx_rename"),
        File.join(home_dir, "xxx_rename")
      ]
    end
  end
end
