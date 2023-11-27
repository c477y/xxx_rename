# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::Tushy do
  include_context "config provider"
  include_context "actor-helper stubber"

  subject { described_class.new }

  let(:override_config) do
    {
      "site" => {
        "tushy" => {
          "file_source_format" => ["[Tushy] %female_actors - %title"]
        }
      }
    }
  end

  let(:scene_data) do
    XxxRename::Data::SceneData.new(
      female_actors: ["Azul Hermosa"],
      male_actors: ["Mick Blue"],
      actors: ["Azul Hermosa", "Mick Blue"],
      collection: "TUSHY",
      collection_tag: "TU",
      title: "Seal The Deal",
      id: 103_765,
      date_released: Time.parse("2022-12-18 18:30:00")
    )
  end

  context "processed file" do
    let(:filename) { "[Tushy] Azul Hermosa - Seal The Deal" }
    let(:parsed_scene_data) do
      XxxRename::Data::ParsedSceneData.new(
        female_actors: ["Azul Hermosa"],
        male_actors: [],
        actors: ["Azul Hermosa"],
        collection: "TUSHY",
        title: "Seal The Deal"
      )
    end
    let(:unprocessed) { false }

    before do
      stub_actor(config, "Azul Hermosa", "female")
      stub_actor(config, "Mick Blue", "male")
      VCR.use_cassette("tushy/seal_the_deal#processed#success") do
        @result = subject.search(filename, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
      end
    end

    it { expect(@result).to match(scene_data) }
  end
end
