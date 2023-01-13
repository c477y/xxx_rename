# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_client_matcher"

describe XxxRename::SiteClientMatcher do
  let(:examples) { JSON.parse(File.read("spec/fixtures/file_rename_examples.json")) }
  RSpec.shared_examples "valid site client matcher - multiple files" do
    it "should return correct site client" do
      expect(matcher).to receive(:generate_class).with(site).and_return(site_client)
      received_site_clients = source_files.map { |file| matcher.match(file) }.map { |x| x.map(&:site_client) }
      expect(received_site_clients).to eq(expected_site_clients)
    end
  end

  RSpec.shared_examples "valid site client matcher - single file" do
    it "should return correct site client" do
      expect(matcher).to receive(:generate_class).with(site).and_return(site_client)
      received_site_clients = matcher.match(file).map(&:site_client)
      expect(received_site_clients).to eq(expected_site_clients)
    end
  end

  include_context "config provider" do
    let(:override_config) do
      {
        "site" => {
          "brazzers" => {
            "file_source_format" => ["%title [BZ] %collection %female_actors_prefix %female_actors",
                                     "%female_actors_prefix%female_actors %male_actors_prefix%male_actors [BZ] %collection %title_prefix%title",
                                     "%female_actors_prefix%female_actors %male_actors_prefix%male_actors [BZ] %title %id_prefix %id"]
          },
          "digital_playground" => {
            "file_source_format" => ["%title [DP] %collection %female_actors_prefix %female_actors"]
          },
          "reality_kings" => {
            "file_source_format" => ["%title [RK] %female_actors_prefix %female_actors"]
          },
          "twistys" => {
            "file_source_format" => ["%title [TW] %female_actors_prefix %female_actors"]
          },
          "mofos" => {
            "file_source_format" => ["%title [MF] %female_actors_prefix %female_actors"]
          },
          "babes" => {
            "file_source_format" => ["%title [BA] %collection %female_actors_prefix %female_actors"]
          },
          "goodporn" => {
            "file_source_format" => ["%title [GP] %collection %female_actors_prefix %female_actors"]
          },
          "wicked" => {
            "file_source_format" => ["%title [WI] %female_actors_prefix %female_actors"]
          },
          "nf_busty" => {
            "file_source_format" => []
          },
          "evil_angel" => {
            "file_source_format" => []
          },
          "vixen" => {
            "file_source_format" => ["%female_actors %title_prefix %title [VX] %collection %id_prefix %id",
                                     "%female_actors %male_actors_prefix %male_actors %title_prefix %title " \
                                     "[VX] %collection %id_prefix %id"]
          },
          "whale_media" => {
            "file_source_format" => ["%female_actors %title_prefix %title [WH] %collection %id_prefix %id",
                                     "%female_actors %male_actors_prefix %male_actors %title_prefix %title " \
                                     "[WH] %collection %id_prefix %id"]
          },
          "stash" => {
            "file_source_format" => []
          },
          "naughty_america" => {
            "file_source_format" => ["%yyyy-%mm-%dd %female_actors %male_actors_prefix %male_actors %collection_tag_2 %collection"]
          }
        }
      }
    end
  end

  before { XxxRename::ProcessedFile.prefix_hash_set(config.prefix_hash) }

  subject(:matcher) { described_class.new(config, override_site: override_site) }

  describe ".match" do
    let(:override_site) { nil }

    context "unprocessed mg_premium files" do
      let(:source_files) { examples["brazzers"].map { |x| x["source"] } }

      let(:babes) { :babes }
      let(:brazzers) { :brazzers }
      let(:digital_playground) { :digital_playground }
      let(:mofos) { :mofos }
      let(:reality_kings) { :reality_kings }
      let(:twistys) { :twistys }
      let(:babes_site_client) { double("babes") }
      let(:brazzers_site_client) { double("brazzers") }
      let(:digital_playground_site_client) { double("digital_playground") }
      let(:mofos_site_client) { double("mofos") }
      let(:reality_kings_site_client) { double("reality_kings") }
      let(:twistys_site_client) { double("twistys") }
      let(:expected_site_clients_per_match) do
        [babes_site_client, brazzers_site_client, digital_playground_site_client,
         mofos_site_client, reality_kings_site_client, twistys_site_client]
      end

      it "should return mg_premium site clients" do
        expect(matcher).to receive(:generate_class).with(:babes).and_return(babes_site_client)
        expect(matcher).to receive(:generate_class).with(:brazzers).and_return(brazzers_site_client)
        expect(matcher).to receive(:generate_class).with(:digital_playground).and_return(digital_playground_site_client)
        expect(matcher).to receive(:generate_class).with(:mofos).and_return(mofos_site_client)
        expect(matcher).to receive(:generate_class).with(:reality_kings).and_return(reality_kings_site_client)
        expect(matcher).to receive(:generate_class).with(:twistys).and_return(twistys_site_client)

        expected_site_clients = source_files.map { expected_site_clients_per_match }
        received_site_clients = source_files.map { |file| matcher.match(file) }.map { |x| x.map(&:site_client) }
        expect(received_site_clients).to eq(expected_site_clients)
      end
    end

    context "unprocessed evil_angel files" do
      let(:source_files) { examples["evil_angel"].map { |x| x["source"] } }
      let(:site) { :evil_angel }
      let(:site_client) { double("evil_angel") }
      let(:expected_site_clients) { source_files.map { [site_client] } }

      it_should_behave_like "valid site client matcher - multiple files"
    end

    context "unprocessed naughty_america files" do
      let(:source_files) { examples["naughty_america"].map { |x| x["source"] } }
      let(:site) { :naughty_america }
      let(:site_client) { double("naughty_america") }
      let(:expected_site_clients) { source_files.map { [site_client] } }

      it_should_behave_like "valid site client matcher - multiple files"
    end

    context "unprocessed whale_media files" do
      let(:source_files) { examples["whale_media"].map { |x| x["source"] } }
      let(:site) { :whale_media }
      let(:site_client) { double("whale_media") }
      let(:expected_site_clients) { source_files.map { [site_client] } }

      it_should_behave_like "valid site client matcher - multiple files"
    end

    context "unprocessed nf_busty files" do
      let(:source_files) { examples["nf_busty"].map { |x| x["source"] } }
      let(:site) { :nf_busty }
      let(:site_client) { double("nf_busty") }
      let(:expected_site_clients) { source_files.map { [site_client] } }

      it_should_behave_like "valid site client matcher - multiple files"
    end

    context "unprocessed goodporn files" do
      let(:source_files) { examples["goodporn"].map { |x| x["source"] } }
      let(:site) { :goodporn }
      let(:site_client) { double("goodporn") }
      let(:expected_site_clients) { source_files.map { [site_client] } }

      it_should_behave_like "valid site client matcher - multiple files"
    end

    context "when an override site is provided" do
      let(:source_files) { ["abc.xyz"] }
      let(:override_site) { :brazzers }
      let(:site) { :brazzers }
      let(:site_client) { double("brazzers") }
      let(:expected_site_clients) { [[site_client]] }

      it_should_behave_like "valid site client matcher - multiple files"
    end

    context "filename matched by legacy format" do
      let(:file) { "Anal Is The Best Medicine [BZ] Doctor Adventures [F] Devon [M] James Deen.mp4" }
      let(:override_site) { :brazzers }
      let(:site) { :brazzers }
      let(:site_client) { double("brazzers") }
      let(:expected_site_clients) { [site_client] }

      it_should_behave_like "valid site client matcher - single file"
    end

    context "filename matched by one of source_file_format - 1" do
      let(:file) { "[F] Devon [M] James Deen [BZ] Doctor Adventures [T] Anal Is The Best Medicine.mp4" }
      let(:site) { :brazzers }
      let(:site_client) { double("brazzers") }
      let(:expected_site_clients) { [site_client] }

      it_should_behave_like "valid site client matcher - single file"
    end

    context "filename matched by one of source_file_format - 2" do
      let(:file) { "[F] Devon [M] James Deen [BZ] foo [ID] 1234.mp4" }
      let(:site) { :brazzers }
      let(:site_client) { double("brazzers") }
      let(:expected_site_clients) { [site_client] }

      it_should_behave_like "valid site client matcher - single file"
    end

    context "filename is matched by no rules" do
      let(:file) { "1234.mp4" }

      it "returns an empty list" do
        expect(matcher.match(file)).to eq([])
      end
    end
  end

  describe ".disable_site" do
    let(:override_site) { nil }
    let(:brazzers_site_client) { XxxRename::SiteClients::Brazzers.new(config) }

    context "when a site is disabled" do
      before do
        # Initialise the site client
        matcher.send(:initialise_site_client, :brazzers)

        # Then disable it
        matcher.disable_site(brazzers_site_client)
      end

      it "removes the site client from memory" do
        expect(matcher.send(:site_clients)).to eq({ brazzers: nil })
        expect(matcher.site_disabled?(:brazzers)).to be true
      end

      it "new calls to initialise the site client do not initialise it" do
        matcher.send(:initialise_site_client, :brazzers)

        expect(matcher.send(:site_clients)).to eq({ brazzers: nil })
        expect(matcher.site_disabled?(:brazzers)).to be true
      end
    end

    context "when the override site is disabled" do
      let(:override_site) { :brazzers }

      before { matcher.disable_site(brazzers_site_client) }

      it "removes the site client from memory" do
        expect(matcher.send(:site_clients)).to eq({ brazzers: nil })
        expect(matcher.site_disabled?(:brazzers)).to be true
      end
    end
  end
end
