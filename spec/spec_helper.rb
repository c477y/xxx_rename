# frozen_string_literal: true

if ENV["CI"] == "true"
  require "codecov"
  require "simplecov"

  SimpleCov.start
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "xxx_rename"
require "fileutils"
require "json"
require "pry"
require "super_diff/rspec"
require "timecop"
require "webmock/rspec"

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

#
# This monkey patch ensures that xxx_rename
# always creates any temporary files inside
# the project instead of the actual value
# $HOME.
#
module XxxRename
  module SystemConstants
    def home_dir
      "test_folder"
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include FileHelpers

  # Use describe instead of RSpec.describe
  config.expose_dsl_globally = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  original_stderr = $stderr
  original_stdout = $stdout

  config.define_derived_metadata do |metadata|
    # By default, all specs will run in CLI mode
    metadata[:type] = :cli_mode unless metadata[:type]
  end

  config.before(:each, type: :stash_scraper) do
    XxxRename.logger(**{ "mode" => XxxRename::Log::STASHAPP_LOGGING, "verbose" => ENV.fetch("LOG_LEVEL", "INFO") })
  end

  config.before(:each, type: :cli_mode) do
    XxxRename.logger(**{ "mode" => XxxRename::Log::CLI_LOGGING, "verbose" => ENV.fetch("LOG_LEVEL", "INFO") })
  end

  config.before(:all, type: :cli_mode) do
    next unless ENV.fetch("SUPPRESS_LOG", nil).to_s.upcase == "TRUE"

    # suppress logs when running in cli mode
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end

  config.after(:all, type: :cli_mode) do
    next unless ENV.fetch("SUPPRESS_LOG", nil).to_s.upcase == "TRUE"

    $stderr = original_stderr
    $stdout = original_stdout
  end

  config.include_context "stubs provider"
end
