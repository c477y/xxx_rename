# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/wicked"

describe XxxRename::SiteClients::Wicked do
  before { WebMock.allow_net_connect! }

  include_context "config provider"

  describe "file rename operation" do
    let(:scene_data) do
      XxxRename::Data::SceneData.new(
        female_actors: ["Mercedes Carrera"],
        male_actors: ["Tommy Pistol"],
        actors: ["Mercedes Carrera", "Tommy Pistol"],
        collection: "Wicked",
        collection_tag: "WI",
        title: "A Daughters Deception Scene 1",
        id: "163066",
        date_released: Time.parse("2018-10-22"),
        director: "Mike Quasar",
        scene_link: "https://www.wicked.com/en/video/wicked/a-daughters-deception-scene-1/163066",
        scene_cover: "https://transform.gammacdn.com/77344/77344_01/previews/2/371/top_1_resized/77344_01_01.jpg",
        movie: {
          name: "A Daughters Deception",
          date: Time.parse("2019-08-06 00:00:00"),
          url: "https://www.wicked.com/en/movie/A-Daughters-Deception/77344",
          front_image: "https://transform.gammacdn.com/movies/77344/77344_a_daughters_deception_front_400x625.jpg?width=900&height=1272&format=webp",
          back_image: "https://transform.gammacdn.com/movies/77344/77344_a_daughters_deception_back_400x625.jpg?width=900&height=1272&format=webp",
          studio: "wicked"
        }
      )
    end

    let(:output_filename) { "A Daughters Deception Scene 1 [WI] Wicked [F] Mercedes Carrera [M] Tommy Pistol.mp4" }

    context "given an unprocessed file" do
      it_behaves_like "a scene mapper" do
        let(:filename) { "ADaughtersDeceptionScene1_s01_TommyPistol_MercedesCarrera_720p.mp4" }
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
    it_behaves_like "a successful actor matcher" do
      let(:actor) { "Bridgette B." }
      let(:expected_name) { "Bridgette B." }
      let(:expected_gender) { "female" }
    end

    it_behaves_like "a successful actor matcher" do
      let(:actor) { "Bridgette B" }
      let(:expected_name) { "Bridgette B." }
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
