# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::Brazzers do
  include_context "config provider"
  subject { described_class.new }

  let(:correct_filename) { "Anal Is The Best Medicine [BZ] Doctor Adventures [F] Devon [M] James Deen.mp4" }

  let(:scene_data) do
    XxxRename::Data::SceneData.new(
      female_actors: ["Devon"],
      male_actors: ["James Deen"],
      actors: ["Devon", "James Deen"],
      collection: "Doctor Adventures",
      collection_tag: "BZ",
      title: "Anal Is The Best Medicine",
      id: "3901131",
      date_released: Time.parse("2013-12-08"),
      description: "foobar",
      scene_link: "https://www.brazzers.com/video/3901131/anal-is-the-best-medicine"
    )
  end

  context "given a processed file" do
    let(:file) { "Anal Is The Best Medicine [BZ] Doctor Adventures [F] Devon [M] James Deen.mp4" }
    let(:parsed_scene_data) do
      XxxRename::Data::ParsedSceneData.new(
        title: "Anal Is The Best Medicine",
        collection: "Doctor Adventures",
        female_actors: ["Devon"],
        male_actors: ["James Deen"]
      )
    end
    let(:unprocessed) { false }

    before do
      VCR.use_cassette("brazzers_client/anal_is_the_best_medicine") do
        @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
      end
    end

    it { expect(@result).to eq_scene_data(scene_data) }
  end

  context "given an unprocessed file" do
    let(:file) { "anal-is-the-best-medicine_720p.mp4" }
    let(:parsed_scene_data) { XxxRename::Data::ParsedSceneData.blank_data }
    let(:unprocessed) { true }

    before do
      VCR.use_cassette("brazzers_client/anal_is_the_best_medicine_unprocessed") do
        @result = subject.search(file, parsed_scene_data: parsed_scene_data, unprocessed: unprocessed)
      end
    end

    it { expect(@result).to eq_scene_data(scene_data) }
  end
end
