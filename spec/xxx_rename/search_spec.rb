# frozen_string_literal: true

require "rspec"
require "xxx_rename/search"
require "xxx_rename/site_client_matcher"
require "xxx_rename/data/scene_datastore"

describe XxxRename::Search do
  include_context "config provider"
  WebMock.disable_net_connect!

  let!(:c) { config.scene_datastore }

  let(:matcher) { XxxRename::SiteClientMatcher.new(config) }
  let(:datastore) { config.scene_datastore }

  subject(:search) { Dir.chdir("test_folder") { described_class.new(matcher, datastore, false).search(file) } }

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
  before(:each) { FileUtils.touch(File.join("test_folder", file)) }

  describe ".search" do
    context "when datastore does not contain the scene" do
      before { SiteClientStubs::EvilAngel.new(:login, :search, :movie_search) }

      it "returns the scene data" do
        expect(search.scene_data.to_h).to include(expected_scene_data.to_h)
      end

      it "returns the site client" do
        expect(search.site_client).to be_an_instance_of(XxxRename::SiteClients::EvilAngel)
      end

      it "saves the scene in the datastore" do
        path = File.expand_path(File.join("test_folder", file))
        expect(datastore.valid?(search.scene_data, filepath: path)).to be true
      end
    end

    context "when datastore has the scene data" do
      let(:file) { "Stunning Curves, Scene 02 [EA] Stunning Curves [F] Gracie Glam, Keisha Grey [M] Chris Strokes.mp4" }

      before do
        path = File.expand_path(File.join("test_folder", file))
        datastore.create!(expected_scene_data, force: true)
        datastore.register_file(expected_scene_data, path)
      end

      it "returns the scene data" do
        expect(search.scene_data).to eq(expected_scene_data)
      end

      it "returns the site client" do
        expect(search.site_client).to be_an_instance_of(XxxRename::SiteClients::EvilAngel)
      end
    end

    context "when site client is not able to match a scene" do
      let(:file) { "Horny Hosts of Purgatory [EA] Doctor Adventures [F] Dani Daniels, Luna Star [M] Johnny Sins.mp4" }
      before { SiteClientStubs::EvilAngel.new(:login, :no_results_search) }

      let(:expected_validity_errors) do
        {
          conflicting_indexes: {},
          missing_keys: %i[id_index collection_title_index title_actors_index path],
          scene_saved: false
        }
      end

      it "returns nil for scene_data" do
        expect(search.scene_data).to eq(nil)
      end

      it "returns nil for site_client" do
        expect(search.site_client).to eq(nil)
      end

      it "saves nothing in the datastore" do
        path = File.expand_path(File.join("test_folder", file))
        valid_check_results = datastore.valid?(expected_scene_data, filepath: path).to_h
        expect(valid_check_results).to include(expected_validity_errors)
      end

      it "does not disable the site client" do
        search
        expect(matcher.site_disabled?(:evil_angel)).to be false
      end
    end

    context "when site client returns a fatal error" do
      before { SiteClientStubs::EvilAngel.new(:login, :service_unavailable) }

      it "returns nil for scene_data" do
        expect(search.scene_data).to eq(nil)
      end

      it "returns nil for site_client" do
        expect(search.site_client).to eq(nil)
      end

      it "disables the site client" do
        search
        expect(matcher.site_disabled?(:evil_angel)).to be true
      end
    end
  end
end
