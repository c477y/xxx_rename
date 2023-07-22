# frozen_string_literal: true

require "rspec"
require "deep_merge/rails_compat"
require "xxx_rename/contract/config_generator"

shared_context "config provider" do
  # Input: Pass some keys in this hash to override default keys
  let(:override_config) { {} }

  # Output: Access config
  let(:config) { XxxRename::Contract::ConfigGenerator.new({ "config" => config_file }).generate! }

  ## Setup

  before(:example) do
    allow_any_instance_of(XxxRename::SystemConstants).to receive(:home_dir).and_return("test_folder")
    FileUtils.mkpath(File.join("test_folder", ".config", "xxx_rename", "generated", "output"))
    write_config_file
  end

  after(:example) do
    FileUtils.rm_r "test_folder"
  end

  def default_config
    XxxRename::Contract::ConfigGenerator.new({}).default_config
  end

  def write_config_file
    config = override_config.deeper_merge(default_config)
    File.open(config_file, "w") { |f| f.write(config.to_yaml) }
  end

  def config_file
    @config_file ||= File.join("test_folder", ".config", "xxx_rename", "config.yml")
  end
end
