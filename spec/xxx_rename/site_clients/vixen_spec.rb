# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/vixen"

describe XxxRename::SiteClients::Vixen do
  before { WebMock.allow_net_connect! }

  include_context "config provider"

  before do
    matcher = XxxRename::SiteClientMatcher.new(config)
    XxxRename::ActorsHelper.instance.matcher(matcher)
  end

  let(:opts) { {} }
  let(:scene_data) do
    XxxRename::Data::SceneData.new(
      female_actors: ["Sienna Day"],
      male_actors: [],
      actors: ["Sienna Day"],
      collection: "CHANNELS",
      collection_tag: "VX",
      title: "Our Summer Of Love 3",
      id: 102_217,
      date_released: Time.parse("2020-02-23")
    )
  end
  let(:output_filename) { "Sienna Day [T] Our Summer Of Love 3 [VX] CHANNELS [ID] 102217.mp4" }

  context "given an already processed filename" do
    it_behaves_like "a scene mapper" do
      let(:filename) { output_filename }
    end
  end

  context "given an already processed filename" do
    it_behaves_like "a scene mapper" do
      let(:opts) { {} }
      let(:filename) { "CHANNELS_102217_480P.mp4" }
      let(:output_filename) { "Sienna Day [T] Our Summer Of Love 3 [VX] CHANNELS [ID] 102217.mp4" }
    end
  end

  context "given an invalid file" do
    it_behaves_like "a nil scene mapper" do
      let(:opts) { {} }
      let(:filename) { "INVALID_102217_480P.mp4" }
    end
  end
end
