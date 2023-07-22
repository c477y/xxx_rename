# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/evil_angel"

describe XxxRename::SiteClients::EvilAngel do
  before { WebMock.allow_net_connect! }
  include_context "config provider"

  describe "file rename operation" do
    let(:output_filename) { "Lex's Breast Fest, Scene 03 [EA] Lex's Breast Fest [F] Bridgette B [M] Lexington Steele.mp4" }
    let(:scene_data) do
      XxxRename::Data::SceneData.new(
        { female_actors: ["Bridgette B"],
          male_actors: ["Lexington Steele"],
          actors: ["Bridgette B", "Lexington Steele"],
          collection: "Evilangel",
          collection_tag: "EA",
          title: "Lex's Breast Fest, Scene #03",
          id: "59022",
          date_released: Time.parse("2013-09-15"),
          director: "Lexington Steele",
          scene_link: "https://www.evilangel.com/en/video/evilangel/lexs-breast-fest-scene-03/59022",
          scene_cover: "https://transform.gammacdn.com/21798/21798_03/previews/2/128/top_1_resized/21798_03_01.jpg",
          movie: { name: "Lex's Breast Fest",
                   date: Time.parse("2013-07-26"),
                   url: "https://www.evilangel.com/en/movie/Lexs-Breast-Fest/21798",
                   front_image: "https://transform.gammacdn.com/movies/21798/21798_lexs_breast_fest_front_400x625.jpg?width=900&height=1272&format=webp",
                   back_image: "https://transform.gammacdn.com/movies/21798/21798_lexs_breast_fest_back_400x625.jpg?width=900&height=1272&format=webp",
                   studio: "Evilangel" } }
      )
    end

    context "given an unprocessed file" do
      it_behaves_like "a scene mapper" do
        let(:filename) { "LexsBreastFest_s03_LexingtonSteele_BridgetteB_540p.mp4" }
      end
    end

    context "given an processed file" do
      it_behaves_like "a scene mapper" do
        let(:filename) { output_filename }
      end
    end

    context "given an invalid filename" do
      it_behaves_like "a nil scene mapper" do
        let(:opts) { {} }
        let(:filename) { "shes1.720p.mp4" }
      end
    end
  end

  describe ".actor_details" do
    subject(:call) { described_class.new(config).actor_details(actor) }

    it_behaves_like "a successful actor matcher" do
      let(:actor) { "Bridgette B." }
      let(:expected_name) { "Bridgette B" }
      let(:expected_gender) { "female" }
    end

    it_behaves_like "a successful actor matcher" do
      let(:actor) { "Bridgette B" }
      let(:expected_name) { "Bridgette B" }
      let(:expected_gender) { "female" }
    end

    it_behaves_like "a successful actor matcher" do
      let(:actor) { "Tommy Gunn" }
      let(:expected_name) { "Tommy Gunn" }
      let(:expected_gender) { "male" }
    end

    it_behaves_like "a nil actor matcher"
  end
end
