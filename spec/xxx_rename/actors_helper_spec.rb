# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/brazzers"
require "xxx_rename/site_clients/evil_angel"
require "xxx_rename/site_clients/reality_kings"
require "xxx_rename/site_clients/wicked"

describe XxxRename::ActorsHelper do
  include_context "config provider"

  subject(:call) { config.actor_helper }
  let(:actor_details) { double(XxxRename::FetchActorDetails) }
  let(:matcher) { XxxRename::SiteClientMatcher.new(config) }

  before do
    expect(XxxRename::FetchActorDetails).to receive(:new).and_return(actor_details)
  end

  context "successful actor match" do
    let(:actor) { "Bridgette B" }
    let(:compressed_name) { "bridgetteb" }

    before do
      expect(actor_details).to receive(:details).and_return(
        {
          "name" => actor,
          "gender" => "female"
        }
      )
      call.auto_fetch!(actor)
    end

    it "actor specific methods should return correct response" do
      expect(call.female?(actor)).to eq(true)
      expect(call.male?(actor)).to eq(false)
    end
  end

  context "duplicate actor match" do
    let(:actor) { "Bridgette B" }
    let(:actor_alias) { "Bridgette B." }

    before do
      expect(actor_details).to receive(:details).with(actor).and_return(
        {
          "name" => actor,
          "gender" => "female"
        }
      )
      expect(actor_details).to receive(:details).with(actor_alias).and_return(
        {
          "name" => actor_alias,
          "gender" => "female"
        }
      )
      call.auto_fetch!(actor)
      call.auto_fetch!(actor_alias)
    end

    it "actor specific methods should return correct response" do
      expect(call.female?(actor)).to eq(true)
      expect(call.male?(actor)).to eq(false)
    end
  end

  context "male and female actor match" do
    let(:female_actor) { "Bridgette B" }
    let(:male_actor) { "Keiran Lee" }

    before do
      expect(actor_details).to receive(:details).with(female_actor).and_return(
        {
          "name" => female_actor,
          "gender" => "female"
        }
      )
      expect(actor_details).to receive(:details).with(male_actor).and_return(
        {
          "name" => male_actor,
          "gender" => "male"
        }
      )
      call.auto_fetch!(female_actor)
      call.auto_fetch!(male_actor)
    end

    it "actor specific methods should return correct response" do
      expect(call.female?(female_actor)).to eq(true)
      expect(call.male?(female_actor)).to eq(false)

      expect(call.female?(male_actor)).to eq(false)
      expect(call.male?(male_actor)).to eq(true)
    end
  end

  context "no actor is matched" do
    let(:actor) { "abc" }

    before do
      expect(actor_details).to receive(:details).with(actor).and_return(nil)
    end

    it "raises an error on fetching" do
      expect { call.auto_fetch!(actor) }.to raise_error(XxxRename::Errors::UnprocessedEntity, actor)
    end

    it "actor specific methods should return nil" do
      call.auto_fetch(actor)
      expect(call.female?(actor)).to eq(false)
      expect(call.male?(actor)).to eq(false)
    end
  end
end

describe XxxRename::FetchActorDetails do
  include_context "config provider"

  let(:call) { described_class.new(config.site_client_matcher).details(name) }

  let(:brazzers_client) { instance_double("XxxRename::SiteClients::Brazzers") }
  let(:wicked_client) { instance_double("XxxRename::SiteClients::Wicked") }
  let(:realitykings_client) { instance_double("XxxRename::SiteClients::RealityKings") }
  let(:evilangel_client) { instance_double("XxxRename::SiteClients::EvilAngel") }

  before do
    expect(XxxRename::SiteClients::Brazzers).to receive(:new).and_return(brazzers_client)
    expect(XxxRename::SiteClients::Wicked).to receive(:new).and_return(wicked_client)
    expect(XxxRename::SiteClients::RealityKings).to receive(:new).and_return(realitykings_client)
    expect(XxxRename::SiteClients::EvilAngel).to receive(:new).and_return(evilangel_client)
  end

  let(:site_client_success_response) do
    {
      "name" => name,
      "gender" => gender
    }
  end

  let(:site_client_failure_response) { nil }

  context "when actor match is successful" do
    let(:name) { "Bridgette B." }
    let(:gender) { "female" }
    let(:response) do
      {
        "name" => name,
        "gender" => gender
      }
    end

    context "when first site client returns a successful match" do
      before do
        expect(brazzers_client).to receive(:actor_details).with(name).and_return(site_client_success_response)
      end

      it "returns correct response" do
        expect(call).to eq(response)
      end
    end

    context "when second site client returns a successful match" do
      before do
        expect(brazzers_client).to receive(:actor_details).with(name).and_return(nil)
        expect(wicked_client).to receive(:actor_details).with(name).and_return(site_client_success_response)
      end

      it "returns correct response" do
        expect(call).to eq(response)
      end
    end

    context "when third site client returns a successful match" do
      before do
        expect(brazzers_client).to receive(:actor_details).with(name).and_return(nil)
        expect(wicked_client).to receive(:actor_details).with(name).and_return(nil)
        expect(realitykings_client).to receive(:actor_details).with(name).and_return(site_client_success_response)
      end

      it "returns correct response" do
        expect(call).to eq(response)
      end
    end

    context "when fourth site client returns a successful match" do
      before do
        expect(brazzers_client).to receive(:actor_details).with(name).and_return(nil)
        expect(wicked_client).to receive(:actor_details).with(name).and_return(nil)
        expect(realitykings_client).to receive(:actor_details).with(name).and_return(nil)
        expect(evilangel_client).to receive(:actor_details).with(name).and_return(site_client_success_response)
      end

      it "returns correct response" do
        expect(call).to eq(response)
      end
    end
  end

  context "when actor match is unsuccessful" do
    let(:name) { "Bridgette B." }

    before do
      expect(brazzers_client).to receive(:actor_details).with(name).and_return(nil)
      expect(wicked_client).to receive(:actor_details).with(name).and_return(nil)
      expect(realitykings_client).to receive(:actor_details).with(name).and_return(nil)
      expect(evilangel_client).to receive(:actor_details).with(name).and_return(nil)
    end

    it "returns correct response" do
      expect(call).to eq(nil)
    end
  end
end
