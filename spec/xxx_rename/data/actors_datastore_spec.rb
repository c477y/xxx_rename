# frozen_string_literal: true

require "rspec"
require "xxx_rename/data/actors_datastore"

RSpec.describe XxxRename::Data::ActorsDatastoreQuery do
  include_context "config provider"

  subject(:data_store) { described_class.new(store, Mutex.new) }

  let(:store) { XxxRename::Data::ActorsDatastore.new("test_folder").store }
  let(:actor) { "Actor" }
  let(:female) { "FEMALE" }
  let(:male) { "MALE" }
  let(:invalid_gender) { "invalid_gender" }

  describe ".create!" do
    context "when actor details are valid" do
      before { data_store.create!(actor, female) }

      it "saves the actor" do
        store.transaction(true) do
          expect(store[actor.normalize]).to eq(female)
        end
      end
    end

    context "when actor details are invalid" do
      let(:error_message) { "expected one of MALE, FEMALE, but got INVALID_GENDER" }

      it "saves the actor" do
        expect { data_store.create!(actor, invalid_gender) }.to raise_error(ArgumentError, error_message)
      end
    end
  end

  describe ".find" do
    context "when actor exists" do
      before { data_store.create!(actor, female) }

      it "returns the actor gender" do
        expect(data_store.find(actor)).to eq("FEMALE")
      end
    end

    context "when actor does not exist" do
      it "returns nil" do
        expect(data_store.find(actor)).to be_nil
      end
    end
  end

  describe "male?" do
    context "when actor exists" do
      before { data_store.create!(actor, male) }

      it "returns true" do
        expect(data_store.male?(actor)).to eq(true)
      end
    end

    context "when actor does not exist" do
      it "returns false" do
        expect(data_store.male?(actor)).to eq(false)
      end
    end
  end

  describe "female?" do
    context "when actor exists" do
      before { data_store.create!(actor, female) }

      it "returns true" do
        expect(data_store.female?(actor)).to eq(true)
      end
    end

    context "when actor does not exist" do
      it "returns false" do
        expect(data_store.female?(actor)).to eq(false)
      end
    end
  end

  describe "count" do
    context "when datastore is empty" do
      it "returns 0" do
        expect(data_store.count).to eq(0)
      end
    end

    context "when datastore contains some actors" do
      before do
        data_store.create!(actor, female)
        data_store.create!("actor 1", female)
        data_store.create!("actor 2", male)
      end

      it "returns the correct count" do
        expect(data_store.count).to eq(3)
      end
    end
  end

  describe "all" do
    context "when datastore is empty" do
      let(:expected) { { FEMALE: [], MALE: [] } }

      it "returns empty hash" do
        expect(data_store.all).to eq(expected)
      end
    end

    context "when datastore contains some data" do
      before do
        data_store.create!(actor, female)
        data_store.create!("actor 1", female)
        data_store.create!("actor 2", male)
      end

      let(:expected) { { FEMALE: %w[actor actor1], MALE: %w[actor2] } }

      it "returns expected response" do
        expect(data_store.all).to eq(expected)
      end
    end
  end
end
