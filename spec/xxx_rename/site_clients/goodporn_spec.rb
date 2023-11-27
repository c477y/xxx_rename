# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::Goodporn do
  include_context "config provider"
  include_context "actor-helper stubber"

  subject { described_class.new }

  describe "valid response" do
    let(:scene_data) do
      XxxRename::Data::SceneData.new(
        female_actors: ["Alexis Ford"],
        male_actors: ["Manuel Ferrara"],
        actors: ["Alexis Ford", "Manuel Ferrara"],
        collection: "Baby Got Boobs",
        collection_tag: "BZ",
        title: "Make It Up To My Dick",
        date_released: Time.parse("2012-02-09"),
        scene_link: "https://goodporn.to/videos/baby-got-boobs-make-it-up-to-my-dick-02-09-2012"
      )
    end

    context "given an unprocessed file" do
      let(:unprocessed) { true }
      let(:filename) { "baby-got-boobs-make-it-up-to-my-dick-02-09-2012_720p.mp4" }
      let(:parsed_scene_data) { XxxRename::Data::ParsedSceneData.blank_data }

      before do
        stub_actor(config, "Alexis Ford", "female")
        stub_actor(config, "Manuel Ferrara", "male")
        VCR.use_cassette("goodporn/unprocessed/make_it_up_to_my_dick") do
          @result = subject.search(filename, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
        end
      end

      it { expect(@result).to eq_scene_data(scene_data) }
    end

    context "given a processed file with date information" do
      let(:unprocessed) { false }
      let(:filename) { "Make It Up To My Dick [GP] Baby Got Boobs [F] Alexis Ford [M] Manuel Ferrara [D] 2012-02-09.mp4" }
      let(:parsed_scene_data) do
        XxxRename::Data::ParsedSceneData.new(
          female_actors: ["Alexis Ford"],
          male_actors: ["Manuel Ferrara"],
          actors: ["Alexis Ford", "Manuel Ferrara"],
          collection: "Baby Got Boobs",
          title: "Make It Up To My Dick",
          date_released: Time.parse("2012-02-09")
        )
      end

      before do
        stub_actor(config, "Alexis Ford", "female")
        stub_actor(config, "Manuel Ferrara", "male")
        VCR.use_cassette("goodporn/unprocessed/make_it_up_to_my_dick") do # use the same cassette
          @result = subject.search(filename, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
        end
      end

      it { expect(@result).to eq_scene_data(scene_data) }
    end

    context "given a processed file with no date information" do
      # scene_link is different when using site search, all other attributes are the same
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          female_actors: ["Alexis Ford"],
          male_actors: ["Manuel Ferrara"],
          actors: ["Alexis Ford", "Manuel Ferrara"],
          collection: "Baby Got Boobs",
          collection_tag: "BZ",
          title: "Make It Up To My Dick",
          date_released: Time.parse("2012-02-09"),
          scene_link: "https://goodporn.to/videos/11087/baby-got-boobs-make-it-up-to-my-dick-02-09-2012/"
        )
      end

      let(:unprocessed) { false }
      let(:filename) { "Make It Up To My Dick [GP] Baby Got Boobs [F] Alexis Ford [M] Manuel Ferrara.mp4" }
      let(:parsed_scene_data) do
        XxxRename::Data::ParsedSceneData.new(
          female_actors: ["Alexis Ford"],
          male_actors: ["Manuel Ferrara"],
          actors: ["Alexis Ford", "Manuel Ferrara"],
          collection: "Baby Got Boobs",
          title: "Make It Up To My Dick"
        )
      end

      before do
        stub_actor(config, "Alexis Ford", "female")
        stub_actor(config, "Manuel Ferrara", "male")
        VCR.use_cassette("goodporn/processed/search_make_it_up_to_my_dick") do # use the same cassette
          @result = subject.search(filename, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
        end
      end

      it { expect(@result).to match_scene_data(scene_data) }
    end
  end
end
