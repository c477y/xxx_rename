# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/naughty_america"

describe XxxRename::SiteClients::NaughtyAmerica do
  before { WebMock.allow_net_connect! }
end

describe XxxRename::SiteClients::NaughtyAmerica::NaughtyAmericaScene do
  subject(:call) do
    described_class.new(collection: collection, actors: actors, date_released: date_released,
                        remastered: remastered, title: title, id: id)
  end

  let(:collection) { "Wives on Vacation" }
  let(:actors) { ["Aaliyah Hadid", "Aidra Fox", "JMac"] }
  let(:date_released) { Time.strptime("2017-03-24", "%Y-%m-%d") }
  let(:remastered) { false }
  let(:title) { "Aaliyah Hadid Fucking In The Couch With Her Tits" }
  let(:id) { "22495" }

  describe ".condensed_collection" do
    context "when normalized collection is defined in the case" do
      let(:collection) { "Fast Times" }
      it { expect(call.condensed_collection).to eq("ftna") }
    end

    context "when normalized collection is defined in the case" do
      it { expect(call.condensed_collection).to eq("wov") }
    end
  end

  describe ".condensed_actor" do
    context "when an actor is named differently in the filename" do
    end
  end
end
