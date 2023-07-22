# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/zero_tolerance"

describe XxxRename::SiteClients::ZeroTolerance do
  before { WebMock.allow_net_connect! }

  include_context "config provider" do
    let(:override_config) do
      {
        "site" => {
          "zero_tolerance" => {
            "file_source_format" => [
              "%title %collection_tag_2 %collection %female_actors_prefix %female_actors %male_actors_prefix %male_actors",
              "%title %collection_tag_2 %collection %female_actors_prefix %female_actors"
            ]
          }
        }
      }
    end
  end

  let(:file1) { "When the Dads away the Moms will play [C] Zero Tolerance Films [F] Alyssa Lynn, Britney Amber [M] Van Wylde.mp4" }

  # examples to test with different names
  let(:file2) do
    "Two Girls Sucking One Sex Toy Bonus Scene [C] Zero Tolerance Films [F] " \
    "Ally Kay, Ashlyn Rae, Breanne Benson, Chastity Lynn, Tiffany Tyler, Victoria White.mp4"
  end

  let(:scene_data1) do
    XxxRename::Data::SceneData.new(
      { female_actors: ["Alyssa Lynn", "Britney Amber"],
        male_actors: ["Van Wylde"],
        actors: ["Alyssa Lynn", "Britney Amber", "Van Wylde"],
        collection: "Zero Tolerance Films",
        collection_tag: "WI",
        title: "When the Dads away the Moms will play",
        id: "178292",
        date_released: Time.parse("2015-05-10"),
        director: "Mike Quasar",
        description: "Sometimes Cougars are on the prowl just waiting for a moment to take a guy and blow his mind, " \
                      "literally his cock but you get the idea. Van is the lucky guy when Britney Amber calls her " \
                      "friend Alyssa over for some fun.",
        scene_link: "https://www.zerotolerancefilms.com/en/video/zerotolerancefilms/when-the-dads-away-the-moms-will-play/178292",
        scene_cover: "https://transform.gammacdn.com/80619/80619_03/previews/2/507/top_1_1920x1080/80619_03_01.jpg",
        movie:
          { name: "Cougar Sandwich",
            date: Time.parse("2020-10-08"),
            url: "https://www.zerotolerancefilms.com/en/movie/Cougar-Sandwich/80619",
            front_image: "https://transform.gammacdn.com/movies/80619/80619_cougar_sandwich_front_400x625.jpg?width=900&height=1272&format=webp",
            back_image: "https://transform.gammacdn.com/movies/80619/80619_cougar_sandwich_back_400x625.jpg?width=900&height=1272&format=webp",
            studio: "Zero Tolerance Films",
            synopsis: "Two cougars are better than one! We double-dare you to take on two hot mamas at a time in this twice..." } }
    )
  end

  describe ".search" do
    subject(:search) { described_class.new(config).search(file) }

    context "with successful match" do
      let(:file) { file1 }

      it "returns scene data" do
        expect(search).to match(scene_data1)
      end
    end

    context "when file does not match format" do
      let(:file) { "foo bar.mp4" }

      it "raises error" do
        expect { search }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError, "No metadata parsed from file")
      end
    end
  end
end
