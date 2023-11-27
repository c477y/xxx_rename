# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
# loader.inflector.inflect("xxx_rename" => "XxxRename")
loader.setup

require "active_support"
require "active_support/core_ext"
require "awesome_print"
require "benchmark"
require "colorize"
require "date"
require "deep_merge/rails_compat"
require "dry-struct"
require "dry-types"
require "dry-validation"
require "fileutils"
require "httparty"
require "nokogiri"
require "pathname"
require "pstore"
require "set"
require "thor"
require "yaml"

require "pry" if ENV.fetch("RACK_ENV", "").match?(/(dev.*|test)/)

# Monkey Patches
require_relative "xxx_rename/core_extensions/string"
String.include XxxRename::CoreExtensions::String

module XxxRename
  def self.logger(**opts)
    @logger ||= XxxRename::Log.new(opts["mode"], opts["verbose"]).logger
  end

  # @return [XxxRename::Data::Config]
  # @raise [Errors::FatalError] if the config is not initialised
  def self.config
    raise Errors::FatalError, "tried to access config, but it was not assigned" unless defined?(@config)

    @config
  end

  #
  # This is called automatically as soon as Config instance is initialised.
  # Now we have access to config globally and can be called by any class
  # @param [XxxRename::Data::Config] config
  def self.config_set(config)
    if config.class.name != Data::Config.name
      raise ArgumentError,
            "expected to set config #{Data::Config.class.name}, but received type #{config.class.name}"
    end

    @config = config
  end
end
