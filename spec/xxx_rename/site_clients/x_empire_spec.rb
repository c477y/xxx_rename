# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::XEmpire do
  describe ".search" do
    include_context "config provider"
    subject { described_class.new }

    let(:override_config) do
      {
        "site" => {
          "hardx" => {
            "file_source_format" => [
              "%title %collection_tag_2 %collection %female_actors_prefix %female_actors %male_actors_prefix %male_actors"
            ]
          }
        }
      }
    end
    let(:file) { "Deep Down Under.mp4" }

    context "with successful match" do
      let(:parsed_scene_data) do
        XxxRename::Data::ParsedSceneData.new(
          title: "Deep Down Under",
          collection: "HardX",
          female_actors: ["Hayley Davies"],
          male_actors: ["Zac Wild"]
        )
      end

      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          { female_actors: ["Hayley Davies"],
            male_actors: ["Zac Wild"],
            actors: ["Hayley Davies", "Zac Wild"],
            collection: "X Empire",
            collection_tag: "XM",
            title: "Deep Down Under",
            id: "246983",
            date_released: Time.parse("2024-04-06"),
            director: "Mason",
            description: "Zac Wild takes his cock down under and deep inside Hayley Davies' tight Aussie pussy.",
            scene_link: "https://www.hardx.com/en/video/hardx/deep-down-under/246983",
            scene_cover: "https://transform.gammacdn.com/119797/119797_01/previews/11/68/top_1_1920x1080/119797_01_01.jpg",
            movie: { name: "Deep Down Under",
                     date: Time.parse("2024-02-13"),
                     url: "https://www.hardx.com/en/movie/Deep-Down-Under/119797",
                     front_image: "https://transform.gammacdn.com/movies/119797/119797_deep_down_under_front_400x625.jpg?width=900&height=1272&format=webp",
                     back_image: "https://transform.gammacdn.com/movies/119797/119797_deep_down_under_back_400x625.jpg?width=900&height=1272&format=webp",
                     studio: "XEmpire",
                     synopsis: "" } }
        )
      end

      before do
        VCR.use_cassette("x_empire_client/deep_down_under#success") do
          @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: false)
        end
      end

      it { expect(@result).to match(scene_data) }
    end

    context "with unsuccessful match" do
      let(:file) { "foo bar abcd [C] Zero Tolerance Films [F] foo bar abcd.mp4" }

      let(:parsed_scene_data) do
        XxxRename::Data::ParsedSceneData.new(
          title: "foo bar abcd",
          collection: "HardX",
          female_actors: ["foo bar abcd"]
        )
      end

      it "raises error" do
        expect do
          VCR.use_cassette("x_empire_client/unsuccess") do
            subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: false)
          end
        end.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
      end
    end
  end
end
