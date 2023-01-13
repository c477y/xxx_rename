# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/goodporn"

describe XxxRename::SiteClients::Goodporn do
  before { WebMock.allow_net_connect! }
  include_context "config provider"

  describe "valid response" do
    let(:scene_data) do
      XxxRename::Data::SceneData.new(
        female_actors: ["Alexis Ford"],
        male_actors: ["Manuel Ferrara"],
        actors: ["Alexis Ford", "Manuel Ferrara"],
        collection: "Baby Got Boobs",
        collection_tag: "GP",
        title: "Make It Up To My Dick",
        id: nil,
        date_released: Time.parse("2012-02-09")
      )
    end
    let(:output_filename) { "Make It Up To My Dick [GP] Baby Got Boobs [F] Alexis Ford [M] Manuel Ferrara.mp4" }

    context "given an unprocessed file" do
      it_behaves_like "a scene mapper" do
        let(:filename) { "baby-got-boobs-make-it-up-to-my-dick-02-09-2012_720p.mp4" }
      end
    end

    context "given an processed file" do
      pending "Goodporn client is not idempotent"
    end

    context "given an invalid filename" do
      it_behaves_like "a nil scene mapper" do
        let(:opts) { {} }
        let(:filename) { "shes1.720p.mp4" }
      end
    end
  end
end
