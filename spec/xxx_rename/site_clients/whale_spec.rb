# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::Whale do
  include_context "config provider"
  subject { described_class.new }

  let(:output_file) { "Keely Rose [T] Keely Rose [WH] Casting Couch X.mp4" }
  let(:scene_data) do
    XxxRename::Data::SceneData.new(
      female_actors: ["Keely Rose"],
      male_actors: [],
      actors: ["Keely Rose"],
      collection: "Casting Couch X",
      collection_tag: "WH",
      title: "Keely Rose",
      id: ""
    )
  end

  context "given an unprocessed file" do
    let(:unprocessed) { true }
    let(:file) { "castingcouchx-keely-rose-720.mp4" }

    let(:parsed_scene_data) do
      h = XxxRename::Constants::WHALE_ORIGINAL_FILE_PATTERN.match(file).named_captures
      XxxRename::Data::ParsedSceneData.new(h)
    end

    before do
      VCR.use_cassette("whale_client/casting_couch_keely_rose#unprocessed#success") do
        @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
      end
    end

    it { expect(@result).to match(scene_data) }
  end

  context "given a processed file" do
    let(:unprocessed) { false }
    let(:file) { output_file }
    let(:parsed_scene_data) do
      XxxRename::Data::ParsedSceneData.new(
        female_actors: ["Keely Rose"],
        male_actors: [],
        actors: ["Keely Rose"],
        collection: "Casting Couch X",
        collection_tag: "WH",
        title: "Keely Rose",
        id: ""
      )
    end

    before do
      VCR.use_cassette("whale_client/casting_couch_keely_rose#processed#success") do
        @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
      end
    end

    it { expect(@result).to match(scene_data) }
  end
end
