# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/tushy"

describe XxxRename::SiteClients::Tushy do
  include_context "config provider" do
    let(:override_config) do
      {
        "site" => {
          "tushy" => {
            "file_source_format" => ["[Tushy] %female_actors - %title"]
          }
        }
      }
    end
  end

  let(:opts) { {} }
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
  let(:input_filename) { "[Tushy] Azul Hermosa - Seal The Deal" }

  before do
    @vixen = SiteClientStubs::VixenMedia.new(:tushy_search_ok)
    @brazzers = SiteClientStubs::Brazzers.new(:actor_search)
    WebMock.disable_net_connect!(allow: "https://www.brazzers.com")
  end

  after do
    @vixen.cleanup
    @brazzers.cleanup
    WebMock.reset!
  end

  context "given a file with custom format" do
    it_behaves_like "a scene mapper" do
      let(:filename) { input_filename }
    end
  end
end
