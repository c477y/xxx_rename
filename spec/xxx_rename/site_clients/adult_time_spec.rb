# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/adult_time"

describe XxxRename::SiteClients::AdultTime do
  before { WebMock.allow_net_connect! }
  include_context "config provider" do
    let(:override_config) do
      { "site" => {
        "adult_time" => {
          "file_source_format" => [
            "%title [C] %collection [F] %female_actors [M] %male_actors"
          ]
        }
      } }
    end
  end

  let(:filename1) { "Wife Swappers - Part 4 [C] Vivid [F] Monique Alexander [M] Trent Tesoro.mp4" }
  let(:scene_data1) do
    {
      female_actors: ["Monique Alexander"],
      male_actors: ["Trent Tesoro"],
      actors: ["Monique Alexander", "Trent Tesoro"],
      collection: "Vivid",
      collection_tag: "AT",
      title: "Wife Swappers - Part 4",
      id: "139185",
      date_released: Time.parse("2010-02-23")
    }
  end

  let(:filename2) { "Worst Day EVER [C] Fantasy Massage [F] Abella Danger [M] Zac Wild.mp4" }
  let(:scene_data2) do
    {
      female_actors: ["Abella Danger"],
      male_actors: ["Zac Wild"],
      actors: ["Abella Danger", "Zac Wild"],
      collection: "Fantasy Massage",
      collection_tag: "AT",
      title: "Worst Day EVER!",
      id: "146279",
      date_released: Time.parse("2019-06-21")
    }
  end
  let(:filename3) { "Down The Hatch 23 - Scene 2 [C] AdultTime [F] Courtney Cummz [M] Prince Yahshua.mp4" }
  let(:scene_data3) do
    {
      female_actors: ["Courtney Cummz"],
      male_actors: ["Prince Yahshua"],
      actors: ["Courtney Cummz", "Prince Yahshua"],
      collection: "Fantasy Massage",
      collection_tag: "AT",
      title: "Down The Hatch 23 - Scene 2",
      id: "146279",
      date_released: Time.parse("2019-06-21")
    }
  end

  describe ".search" do
    subject(:search) { described_class.new(config).search(filename) }

    context "when studio is matched as vivid" do
      let(:filename) { filename1 }
      let(:scene_data) { scene_data1 }

      it "returns the expected response" do
        expect(search.to_h).to include(scene_data1)
      end
    end

    context "when studio is matched as fantasy massage" do
      let(:filename) { filename2 }
      let(:scene_data) { scene_data2 }

      it "returns the expected response" do
        expect(search.to_h).to include(scene_data)
      end
    end
  end
end
