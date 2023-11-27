# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::Wicked do
  describe ".search" do
    include_context "config provider"
    subject { described_class.new }

    let(:override_config) do
      {
        "site" => {
          "wicked" => {
            "file_source_format" => [
              "%title %collection_tag_2 %collection %female_actors_prefix %female_actors %male_actors_prefix %male_actors"
            ]
          }
        }
      }
    end

    context "with successful match" do
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          { female_actors: ["Samantha Saint"],
            male_actors: ["Steven St. Croix"],
            actors: ["Samantha Saint", "Steven St. Croix"],
            collection: "Wicked",
            collection_tag: "WI",
            title: "The Party Scene 1",
            id: "161989",
            date_released: Time.parse("2014-10-27"),
            director: "Jonathan Morgan",
            description: "",
            scene_link: "https://www.wicked.com/en/video/wicked/the-party-scene-1/161989",
            scene_cover: "https://transform.gammacdn.com/77133/77133_01/previews/2/371/top_1_resized/77133_01_01.jpg",
            movie: { name: "The Party",
                     date: Time.parse("2019-08-06"),
                     url: "https://www.wicked.com/en/movie/The-Party/77133",
                     front_image: "https://transform.gammacdn.com/movies/77133/77133_the_party_front_400x625.jpg?width=900&height=1272&format=webp",
                     back_image: "https://transform.gammacdn.com/movies/77133/77133_the_party_back_400x625.jpg?width=900&height=1272&format=webp",
                     studio: "wicked",
                     synopsis: "It's New Year's Day and our cast of characters (a businessman, his younger wife and two ex-wives) " \
                       "are nursing hangovers and trying to piece together what happened the night before. Through a series " \
                       "of flashbacks, we learn that partying and hyperactive libidos were responsible for shredded business " \
                       "documents, a facial tattoo and wild, no-holds barred sex! Funny, Irreverent and Hot as Hell ... RSVP today for The Party!" } }
        )
      end

      context "unprocessed file" do
        let(:file) { "ThePartyScene1_s01_StevenStCroix_SamanthaSaint_720p.mp4" }
        let(:parsed_scene_data) { XxxRename::Data::ParsedSceneData.new }
        let(:unprocessed) { true }

        before do
          VCR.use_cassette("wicked_client/the_party_scene_1#unprocessed#success") do
            @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
          end
        end

        it { expect(@result).to match(scene_data) }
      end

      context "processed file" do
        let(:file) { "ThePartyScene1.mp4" }
        let(:parsed_scene_data) do
          XxxRename::Data::ParsedSceneData.new(
            title: "The Party Scene 1",
            collection: "Wicked",
            female_actors: ["Samantha Saint"]
          )
        end
        let(:unprocessed) { false }

        before do
          VCR.use_cassette("wicked_client/the_party_scene_1#processed#success") do
            @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
          end
        end

        it { expect(@result).to match(scene_data) }
      end
    end

    context "with unsuccessful match" do
      let(:file) { "foo bar abcd [C] Wicked [F] foo bar abcd.mp4" }

      let(:parsed_scene_data) do
        XxxRename::Data::ParsedSceneData.new(
          title: "foo bar abcd",
          collection: "Wicked",
          female_actors: ["foo bar abcd"]
        )
      end

      it "raises error" do
        expect do
          VCR.use_cassette("wicked_client/unsuccess") do
            subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: false)
          end
        end.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
      end
    end
  end
end
