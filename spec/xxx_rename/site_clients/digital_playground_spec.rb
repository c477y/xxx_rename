# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/digital_playground"

describe XxxRename::SiteClients::DigitalPlayground do
  include_context "config provider"

  subject(:call) do
    described_class.new(config)
  end

  before do
    expect(call).to receive(:refresh_token_mg).with("https://www.digitalplayground.com").and_return("instance token")
  end

  context "given a processed file that belongs to a movie" do
    let(:file) { "Exposure Scene 3 [GP] Blockbuster [F] Angela White, Gianna Dior [M] Ramon Nomar.mp4" }
    let(:expected_response) do
      XxxRename::Data::SceneData.new(
        female_actors: ["Angela White", "Gianna Dior"],
        male_actors: ["Ramon Nomar"],
        actors: ["Angela White", "Gianna Dior", "Ramon Nomar"],
        collection: "Blockbuster",
        collection_tag: "DP",
        title: "Exposure: Scene 3",
        id: "4395046",
        date_released: Time.parse("2019-09-25T00:00:00+00:00"),
        movie: {
          name: "Exposure",
          date: Time.parse("2019-09-25T00:00:00+00:00"),
          url: "https://www.digitalplayground.com/movie/4395043/exposure",
          front_image: "https://media-public-ht.project1content.com/m=eIAbaWhWx/634/d2a/485/56c/4e0/4be/0e4/282/bca/b53/c4/cover/cover_01.jpg",
          studio: "Digital Playground",
          synopsis: "Chelsea Declan is a model turned successful photographer. While she is heavily sought after " \
                    "in the “pop” world, she isn’t taken seriously by the more pretentious art crowd, largely due " \
                    "to her sexual and professional history with arthouse photographer Dennis Paul, who takes credit " \
                    "for “making” her. When Chelsea discovers she’s up against Dennis for a high-profile job, she " \
                    "decides she’ll do whatever it takes to land the job and show up her possessive former mentor."
        }
      )
    end

    before do
      search_results = File.read(File.join("spec", "fixtures", "digital_playground", "scene_search.json"))
      stub_request(:get, "https://site-api.project1service.com/v2/releases")
        .with(query: { limit: 10, search: "exposure scene 3", type: "scene" })
        .to_return(status: 200, body: search_results)
    end

    it "gives the correct response" do
      expect(call.search(file)).to eq(expected_response)
    end
  end

  context "given a processed file that belongs to a series" do
    let(:file) { "Word Of Mouth Episode 2 [GP] Episodes [F] Dana DeArmond [M] Ricky Johnson.mp4" }
    let(:expected_response) do
      XxxRename::Data::SceneData.new(
        female_actors: ["Dana DeArmond"],
        male_actors: ["Ricky Johnson"],
        actors: ["Dana DeArmond", "Ricky Johnson"],
        collection: "Episodes",
        collection_tag: "DP",
        title: "Word Of Mouth: Episode 2",
        id: "4353221",
        date_released: Time.parse("2019-04-15T00:00:00+00:00"),
        movie: {
          name: "Word Of Mouth",
          date: Time.parse("2019-04-08T00:00:00+00:00"),
          url: "https://www.digitalplayground.com/series/4352467/word-of-mouth",
          front_image: "https://media-public-ht.project1content.com/m=ea_aGJcWx/bc3/1e1/71d/ee6/447/5b0/1f2/e71/bc7/018/db/poster/poster_01.jpg",
          studio: "Digital Playground",
          synopsis: "Ricky Johnson lives a pretty boring existence. He flips burgers by day and watches TV at night. " \
                    "He has no idea a one night stand is about to change his life forever. Beverly Hills is full of " \
                    "rich, horny women who crave fuss-free sex… and are willing to pay more than a pretty penny for it. " \
                    "Thanks to word of mouth, Ricky spends his days pleasing hot housewives and earning big bucks. " \
                    "Can he keep up with the demands of the world’s most privileged women?"
        }
      )
    end

    before do
      search_results = File.read(File.join("spec", "fixtures", "digital_playground", "series_scene_search.json"))
      stub_request(:get, "https://site-api.project1service.com/v2/releases")
        .with(query: { limit: 10, search: "word of mouth episode 2", type: "scene" })
        .to_return(status: 200, body: search_results)
    end

    it "gives the correct response" do
      expect(call.search(file)).to eq(expected_response)
    end
  end
end
