# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::ZeroTolerance do
  describe ".search" do
    include_context "config provider"

    subject { described_class.new }

    context "with successful match" do
      let(:file) { "When the Dads away the Moms will play [C] Zero Tolerance Films [F] Alyssa Lynn, Britney Amber [M] Van Wylde.mp4" }
      let(:parsed_scene_data) do
        XxxRename::Data::ParsedSceneData.new(
          title: "When the Dads away the Moms will play",
          collection: "Zero Tolerance Films",
          female_actors: ["Alyssa Lynn", "Britney Amber"],
          male_actors: ["Van Wylde"]
        )
      end

      let(:scene_data) do
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

      before do
        VCR.use_cassette("zero_tolerance_client/when_the_dads_away_the_moms_will_play#success") do
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
          collection: "Zero Tolerance Films",
          female_actors: ["foo bar abcd"]
        )
      end

      it "raises error" do
        expect do
          VCR.use_cassette("zero_tolerance_client/unsuccess") do
            subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: false)
          end
        end.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
      end
    end
  end
end
