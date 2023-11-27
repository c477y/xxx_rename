# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::AdultTime do
  include_context "config provider"
  subject { described_class.new }

  describe ".search" do
    context "when studio is matched as vivid" do
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          female_actors: ["Monique Alexander"],
          male_actors: ["Trent Tesoro"],
          actors: ["Monique Alexander", "Trent Tesoro"],
          collection: "Vivid",
          collection_tag: "AT",
          title: "Wife Swappers - Part 4",
          id: "139185",
          date_released: Time.parse("2010-02-23"),
          scene_link: "https://www.milkingtable.com/en/video/vivid/wife-swappers---part-4/139185",
          scene_cover: "https://transform.gammacdn.com/71421/71421_04/previews/2/330/top_1_1920x1080/71421_04_1.jpg"
        )
      end

      let(:file) { "Wife Swappers - Part 4 [C] Vivid [F] Monique Alexander [M] Trent Tesoro.mp4" }
      let(:parsed_scene_data) do
        XxxRename::Data::ParsedSceneData.new(
          title: "Wife Swappers - Part 4",
          collection: "Vivid",
          female_actors: ["Monique Alexander"],
          male_actors: ["Trent Tesoro"]
        )
      end
      let(:unprocessed) { false }

      before do
        VCR.use_cassette("adult_time_client/wife_swappers-part_4") do
          @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
        end
      end

      it "returns the expected response" do
        expect(@result).to eq_scene_data(scene_data)
      end
    end

    context "when studio is matched as fantasy massage" do
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          female_actors: ["Abella Danger"],
          male_actors: ["Zac Wild"],
          actors: ["Abella Danger", "Zac Wild"],
          collection: "Fantasy Massage",
          collection_tag: "AT",
          title: "Worst Day EVER!",
          id: "146279",
          date_released: Time.parse("2019-06-21"),
          director: "Billy Visual",
          scene_link: "https://www.milkingtable.com/en/video/nurumassage/worst-day-ever/146279",
          scene_cover: "https://transform.gammacdn.com/75220/75220_01/previews/2/161/top_1_resized/75220_01_01.jpg"
        )
      end

      let(:file) { "Worst Day EVER [C] Fantasy Massage [F] Abella Danger [M] Zac Wild.mp4" }
      let(:parsed_scene_data) do
        XxxRename::Data::ParsedSceneData.new(
          title: "Worst Day EVER",
          collection: "Fantasy Massage",
          female_actors: ["Abella Danger"],
          male_actors: ["Zac Wild"]
        )
      end
      let(:unprocessed) { false }

      before do
        VCR.use_cassette("adult_time_client/worst_day_ever") do
          @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
        end
      end

      it "returns the expected response" do
        expect(@result).to eq_scene_data(scene_data)
      end
    end
  end
end
