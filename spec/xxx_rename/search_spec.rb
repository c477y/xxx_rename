# frozen_string_literal: true

require "rspec"

describe XxxRename::Search do
  include_context "config provider"

  let!(:c) { config.scene_datastore }

  let(:matcher) { XxxRename::SiteClientMatcher.new }
  let(:datastore) { config.scene_datastore }

  let(:file) { "StunningCurves_s02_GracieGlam_ChrisStrokes_540p.mp4" }
  let(:expected_scene_data) do
    XxxRename::Data::SceneData.new(
      female_actors: ["Gracie Glam", "Keisha Grey"],
      male_actors: ["Chris Strokes"],
      actors: ["Gracie Glam", "Keisha Grey", "Chris Strokes"],
      collection: "Evilangel",
      collection_tag: "EA",
      title: "Stunning Curves, Scene #02",
      id: "73343",
      date_released: Time.parse("2015-04-14 00:00:00")
    )
  end
  before(:each) { FileUtils.touch(file) }

  describe ".search" do
    context "when datastore does not contain the scene" do
      before do
        VCR.use_cassette("search/evil_angel/stunning_curves_scene_02") do
          @result = described_class.new.search(file)
        end
      end

      it "returns the scene data" do
        expect(@result.scene_data.to_h).to include(expected_scene_data.to_h)
      end

      it "returns the site client" do
        expect(@result.site_client).to be_an_instance_of(XxxRename::SiteClients::EvilAngel)
      end

      it "saves the scene in the datastore" do
        path = File.expand_path(file)
        expect(datastore.valid?(@result.scene_data, filepath: path)).to be true
      end
    end

    context "when datastore has the scene data" do
      let(:file) { "Stunning Curves, Scene 02 [EA] Stunning Curves [F] Gracie Glam, Keisha Grey [M] Chris Strokes.mp4" }
      let(:override_config) do
        { "site" => {
          "evil_angel" => {
            "file_source_format" => [
              "%title [EA] %collection [F] %female_actors [M] %male_actors"
            ]
          }
        } }
      end

      before do
        path = File.expand_path(file)
        datastore.create!(expected_scene_data, force: true)
        datastore.register_file(expected_scene_data, path)
      end

      it "returns the scene data" do
        expect(described_class.new.search(file).scene_data).to eq(expected_scene_data)
      end

      it "returns the site client" do
        expect(described_class.new.search(file).site_client).to be_an_instance_of(XxxRename::SiteClients::EvilAngel)
      end
    end

    context "when site client is not able to match a scene" do
      let(:file) { "Horny Hosts of Purgatory [EA] Doctor Adventures [F] Dani Daniels, Luna Star [M] Johnny Sins.mp4" }
      before do
        VCR.use_cassette("search/evil_angel/no_search_results_horny_hosts_of_purgatory") do
          @result = described_class.new.search(file)
        end
      end

      let(:expected_validity_errors) do
        {
          conflicting_indexes: {},
          missing_keys: %i[id_index collection_title_index title_actors_index path],
          scene_saved: false
        }
      end

      it "returns nil for scene_data" do
        expect(@result.scene_data).to eq(nil)
      end

      it "returns nil for site_client" do
        expect(@result.site_client).to eq(nil)
      end

      it "saves nothing in the datastore" do
        path = File.expand_path(file)
        valid_check_results = datastore.valid?(expected_scene_data, filepath: path).to_h
        expect(valid_check_results).to include(expected_validity_errors)
      end

      it "does not disable the site client" do
        expect(matcher.site_disabled?(:evil_angel)).to be false
      end
    end

    # context "when site client returns a fatal error" do
    #   before { SiteClientStubs::EvilAngel.new(:login, :service_unavailable) }
    #
    #   it "returns nil for scene_data" do
    #     expect(search.scene_data).to eq(nil)
    #   end
    #
    #   it "returns nil for site_client" do
    #     expect(search.site_client).to eq(nil)
    #   end
    #
    #   it "disables the site client" do
    #     search
    #     expect(matcher.site_disabled?(:evil_angel)).to be true
    #   end
    # end
  end
end
