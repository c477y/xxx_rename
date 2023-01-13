# frozen_string_literal: true

require "simplecov"
SimpleCov.start

if ENV["CI"] == "true"
  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "xxx_rename"
require "fileutils"
require "json"
require "pry"
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

  # Use describe instead of RSpec.describe
  config.expose_dsl_globally = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  original_stderr = $stderr
  original_stdout = $stdout
  config.before(:all) do
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end
  config.after(:all) do
    $stderr = original_stderr
    $stdout = original_stdout
  end

  config.include_context "stubs provider"
end
