# frozen_string_literal: true

require "rspec"
require "deep_merge/rails_compat"

shared_context "config provider" do
  # Input: Pass some keys in this hash to override default keys
  let(:override_config) { {} }
  let(:override_site) { nil }
  let(:eager_load) { true }

  # Output: Access config
  let(:config) { XxxRename::Contract::ConfigGenerator.new({ "config" => config_file }).generate! }

  ## Setup
  before(:example) do
    allow_any_instance_of(XxxRename::SystemConstants).to receive(:home_dir).and_return(".")
    FileUtils.mkpath(File.join(".config", "xxx_rename", "generated", "output"))
    write_config_file
    config if eager_load
  end

  def default_config
    XxxRename::Contract::ConfigGenerator.new({}).default_config
  end

  def write_config_file
    config = override_config.deeper_merge(default_config)
    config = config.merge("override_site" => override_site.to_s) if override_site.present?
    File.open(config_file, "w") { |f| f.write(config.to_yaml) }
  end

  def config_file
    @config_file ||= File.join(".config", "xxx_rename", "config.yml")
  end
end
