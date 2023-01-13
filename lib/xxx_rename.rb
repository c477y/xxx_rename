# frozen_string_literal: true

require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash/except"

require "date"
require "colorize"
require "deep_merge/rails_compat"
require "dry-types"
require "dry-struct"
require "dry-validation"
require "thor"
require "set"
require "yaml"

require "pry" if ENV["RACK_ENV"] == "development"

require "xxx_rename/log"

module XxxRename
  def self.logger(**opts)
    @logger ||= XxxRename::Log.new(**opts).logger
  end
end

# Monkey Patches
require_relative "xxx_rename/core_extensions/string"
String.include XxxRename::CoreExtensions::String

# Helper files
require_relative "xxx_rename/actors_helper"
require_relative "xxx_rename/constants"
require_relative "xxx_rename/errors"
require_relative "xxx_rename/file_scanner"
require_relative "xxx_rename/file_utilities"
require_relative "xxx_rename/filename_generator"
require_relative "xxx_rename/search"
require_relative "xxx_rename/processed_file"
require_relative "xxx_rename/utils"

# Data Files
require_relative "xxx_rename/data/types"
require_relative "xxx_rename/data/base"
require_relative "xxx_rename/data/site_config"
require_relative "xxx_rename/data/config"
require_relative "xxx_rename/data/naughty_america_database"
require_relative "xxx_rename/data/scene_data"

# Schema Files
require_relative "xxx_rename/contract/types"
require_relative "xxx_rename/contract/config_contract"
require_relative "xxx_rename/contract/config_generator"

# Commands
require_relative "xxx_rename/version"

# Top level modules
require_relative "xxx_rename/cli"
require_relative "xxx_rename/client"
require_relative "xxx_rename/migration_client"
