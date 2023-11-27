# frozen_string_literal: true

require "xxx_rename"

if ENV["CI"] == "true"
  require "codecov"
  require "simplecov"

  SimpleCov.start
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "fileutils"
require "json"
require "pry"
require "super_diff/rspec"
require "timecop"
require "vcr"
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

IGNORED_URLS = [
  "127.0.0.1",
  "host.docker.internal",
  "localhost",
  "www.brazzers.com",
  "www.digitalplayground.com",
  "www.evilangel.com",
  "www.hardx.com",
  "www.wicked.com",
  "www.zerotolerancefilms.com"
].freeze

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock

  config.before_http_request(:recordable?) do
    msg = "Your spec is trying to make a real HTTP request which VCR will store.\n" \
      "Run your spec inside docker to allow this request to be recorded\n" \
      "e.g. ./bin/docker_rspec spec/xxx_download/net/ztod_index_spec.rb"
    raise msg if ENV.fetch("DOCKER_ENV", 0).to_i != 1
  end

  config.ignore_request do |request|
    uri = URI(request.uri)

    IGNORED_URLS.include?(uri.host) || uri.port == 9999
  end

  config.filter_sensitive_data("user") { `echo $HOME`.chomp }
  config.filter_sensitive_data("username") { `whoami`.chomp }
  # config.filter_sensitive_data("<<REDACTED>>") do |interaction|
  #   binding.pry
  # end

  config.before_record do |interaction|
    %w[
      Apikey
      Cf-Cache-Status
      Cf-Ray
      Cookie
      Date
      Etag
      Nel
      Report-To
      Server
      Set-Cookie
      X-Algolia-Api-Key
      X-Algolia-Application-Id
    ].each do |h|
      interaction.response.headers.delete(h)
      interaction.request.headers.delete(h)
    end
  end

  # https://benoittgt.github.io/vcr/#/configuration/preserve_exact_body_bytes
  config.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name == "ASCII-8BIT" || !http_message.body.valid_encoding?
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

  config.define_derived_metadata do |metadata|
    # By default, all specs will run in CLI mode
    metadata[:type] = :cli_mode unless metadata[:type]
  end

  config.around(:each) do |example|
    Dir.mktmpdir("temp_test_dir_", Dir.pwd) do |dir|
      Dir.chdir(dir) do
        example.run
      end
    end
  end

  config.before(:all, type: :cli_mode) do
    level = ENV.fetch("LOG_LEVEL", "WARN")
    XxxRename.logger(**{ "mode" => XxxRename::Log::CLI_LOGGING, "verbose" => level })
  end

  config.before(:each, type: :stash_scraper) do
    XxxRename.logger(**{ "mode" => XxxRename::Log::STASHAPP_LOGGING, "verbose" => ENV.fetch("LOG_LEVEL", "INFO") })
  end

  config.include_context "stubs provider"
end
