# frozen_string_literal: true

require "rspec"
require "xxx_rename/contract/config_generator"
require "xxx_rename/data/file_pre_processor_rule"

RSpec.describe XxxRename::Contract::ConfigGenerator do
  describe(".generate!") do
    subject(:call) { described_class.new(options) }
    let(:generated_config_file) { File.join("test_folder", ".config", "xxx_rename", "config.yml") }

    context "when no config file exists" do
      let(:options) { {} }

      after { FileUtils.rm_r "test_folder" }

      it "should create a config file", :aggregate_failures do
        expect { call.generate! }.to raise_error(XxxRename::Errors::SafeExit, "DEFAULT_FILE_GENERATION")
        expect(File.exist?(generated_config_file)).to be true
      end

      it "creates a valid yaml file", :aggregate_failures do
        expect { call.generate! }.to raise_error(XxxRename::Errors::SafeExit, "DEFAULT_FILE_GENERATION")
        expect { YAML.load_file(generated_config_file) }.not_to raise_error
      end
    end

    context "when a config file exists" do
      include_context "config provider" do
        let(:override_config) { override_config_val }
        let(:eager_load) { false }
      end

      let(:override_config_val) { {} }

      context "when passing override options" do
        context "when overriding female_actors_prefix" do
          let(:options) { { "female_actors_prefix" => "FEMALE" } }

          it "female_actors_prefix should contain the overridden value" do
            female_actors_prefix = call.generate!.global.female_actors_prefix
            expect(female_actors_prefix).to eq("FEMALE")
          end
        end

        context "when overriding multiple global options" do
          let(:options) do
            { "id_prefix" => "ID",
              "title_prefix" => "TITLE" }
          end

          it "generated config should contain the overridden value", :aggregate_failures do
            global = call.generate!.global
            expect(global.id_prefix).to eq("ID")
            expect(global.title_prefix).to eq("TITLE")
          end
        end

        context "when passing true for force_refresh_datastore" do
          let(:options) { { "force_refresh_datastore" => true } }

          it "force_refresh_datastore should be true" do
            expect(call.generate!.force_refresh_datastore).to be true
          end
        end

        context "when passing nil for force_refresh_datastore" do
          let(:options) { { "force_refresh_datastore" => nil } }

          it "force_refresh_datastore should be false" do
            expect(call.generate!.force_refresh_datastore).to be false
          end
        end
      end

      context "when all keys are present in the config file" do
        let(:options) { {} }

        context "when the config file is not modified after creation" do
          it "does not raise any struct validation errors" do
            expect { call.generate! }.not_to raise_error
          end

          it "returns an instance of config struct" do
            expect(call.generate!.class).to eq(XxxRename::Data::Config)
          end
        end

        context "when the config file contains invalid `output_format`" do
          let(:override_config_val) do
            {
              "site" => {
                "brazzers" => {
                  "output_format" => ["%female_actors - %male_actor - %title"]
                }
              }
            }
          end

          it "raises validation error" do
            expect { call.generate! }.to raise_error(XxxRename::Errors::ConfigValidationError,
                                                     "site.brazzers.output_format: invalid token(s) %male_actor")
          end
        end

        context "when config file has clashing `source_file_format`" do
          let(:override_config_val) do
            {
              "site" => {
                "brazzers" => { # duplicate 1
                  "file_source_format" => ["%female_actors [MG] %male_actors - %title"]
                },
                "reality_kings" => { # duplicate 1
                  "file_source_format" => ["%female_actors [MG] %male_actors - %title"]
                },
                "stash" => { # duplicate 2
                  "file_source_format" => ["%title - scene"]
                },
                "whale_media" => { # duplicate 2
                  "file_source_format" => ["%title - scene"]
                },
                "evil_angel" => {
                  "file_source_format" => ["%female_actors [EA] %male_actors - %title"]
                },
                "goodporn" => {
                  "file_source_format" => ["%female_actors [GOODPORN] %male_actors - %title"]
                }
              }
            }
          end

          it "raises validation error" do
            expect { call.generate! }.to raise_error(XxxRename::Errors::ConfigValidationError,
                                                     "duplicate_source_file_format: '%female_actors [MG] %male_actors - %title', '%title - scene'")
          end
        end

        context "when the config file has missing username and present password for stash db" do
          let(:override_config_val) do
            {
              "site" => {
                "stash" => {
                  "username" => "",
                  "password" => "password",
                  "api_token" => ""
                }
              }
            }
          end

          it "raises validation error" do
            expect { call.generate! }
              .to raise_error(XxxRename::Errors::ConfigValidationError,
                              "stash_credentials: provide both username and password if you want to use login credentials")
          end
        end

        context "file_pre_process" do
          let(:override_config_val) do
            {
              "file_pre_process" => [
                {
                  "regex" => regex,
                  "with" => with
                }
              ]
            }
          end

          let(:with) { "FOO" }
          let(:regex) { "\\[XXX\\]" }

          it "contains the default rules" do
            config = call.generate!
            expect(config.file_pre_process[0].to_h).to eq(XxxRename::Data::FilePreProcessorRule::DEFAULT_RULES[0])
            expect(config.file_pre_process[1].to_h).to eq(XxxRename::Data::FilePreProcessorRule::DEFAULT_RULES[1])
          end

          it "contains the new rule" do
            config = call.generate!
            expect(config.file_pre_process.last.to_h).to eq({ regex: "\\[XXX\\]", with: "FOO" })
          end

          context "with valid regex" do
            it "does not raise any validation errors" do
              expect { call.generate! }
                .not_to raise_error(XxxRename::Errors::ConfigValidationError)
            end
          end

          context "with an empty regex" do
            let(:regex) { "" }

            it "raises a validation error" do
              expect { call.generate! }
                .to raise_error(XxxRename::Errors::ConfigValidationError, /file_pre_process.\d.regex: must be filled/)
            end
          end

          context "with an invalid regex" do
            let(:regex) { "((" }
            let(:error_message) { "file_pre_process: Rule (( failed to parse due to error end pattern with unmatched parenthesis: /((/" }

            it "raises a validation error" do
              expect { call.generate! }
                .to raise_error(XxxRename::Errors::ConfigValidationError, error_message)
            end
          end

          context "with an empty replacement" do
            let(:regex) { "\\[XXX\\]" }
            let(:with) { "" }

            it "does not raise any validation errors" do
              expect { call.generate! }
                .not_to raise_error(XxxRename::Errors::ConfigValidationError)
            end
          end
        end
      end

      context "when config file is empty" do
        before do
          File.open(generated_config_file, "w") do |f|
            f.write({}.to_yaml)
          end
        end

        let(:options) { {} }

        it "does not raise any struct validation errors" do
          expect { call.generate! }.not_to raise_error
        end
      end
    end
  end
end
