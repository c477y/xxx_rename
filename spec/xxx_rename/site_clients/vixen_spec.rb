# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::Vixen do
  include_context "config provider"
  include_context "actor-helper stubber"

  subject { described_class.new }

  let(:scene_data) do
    XxxRename::Data::SceneData.new(
      female_actors: ["Sienna Day"],
      male_actors: [],
      actors: ["Sienna Day"],
      collection: "CHANNELS",
      collection_tag: "VX",
      title: "Our Summer Of Love 3",
      id: 102_217,
      date_released: Time.parse("2020-02-23")
    )
  end
  let(:output_file) { "Sienna Day [T] Our Summer Of Love 3 [VX] CHANNELS [ID] 102217.mp4" }

  before { stub_actor(config, "Sienna Day", "female") }

  context "given a already processed file" do
    let(:unprocessed) { false }
    let(:file) { output_file }
    let(:parsed_scene_data) do
      XxxRename::Data::ParsedSceneData.new(
        female_actors: ["Sienna Day"],
        male_actors: [],
        actors: ["Sienna Day"],
        collection: "CHANNELS",
        title: "Our Summer Of Love 3",
        id: "102217"
      )
    end

    before do
      VCR.use_cassette("vixen/our_summer_of_love_3#processed#success") do
        @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
      end
    end

    it { expect(@result).to match(scene_data) }
  end

  context "given an unprocessed file" do
    let(:unprocessed) { false }
    let(:file) { "CHANNELS_102217_480P.mp4" }
    let(:parsed_scene_data) do
      h = XxxRename::Constants::VIXEN_MEDIA_ORIGINAL_FILE_REGEX_1.match(file).named_captures
      XxxRename::Data::ParsedSceneData.new(h)
    end

    before do
      VCR.use_cassette("vixen/CHANNELS_102217#unprocessed#success") do
        @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
      end
    end

    it { expect(@result).to match(scene_data) }
  end
end
