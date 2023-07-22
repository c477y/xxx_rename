# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/whale"

describe XxxRename::SiteClients::Whale do
  include_context "config provider"

  before { WebMock.allow_net_connect! }

  let(:output_filename) { "Keely Rose [T] Keely Rose [WH] Casting Couch X.mp4" }
  let(:scene_data) do
    XxxRename::Data::SceneData.new(
      female_actors: ["Keely Rose"],
      male_actors: [],
      actors: ["Keely Rose"],
      collection: "Casting Couch X",
      collection_tag: "WH",
      title: "Keely Rose",
      id: ""
    )
  end

  context "given an unprocessed file" do
    it_behaves_like "a scene mapper" do
      let(:filename) { "castingcouchx-keely-rose-720.mp4" }
    end
  end

  context "given a processed file" do
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
