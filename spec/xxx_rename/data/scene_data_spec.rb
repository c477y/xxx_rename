# frozen_string_literal: true

require "rspec"

describe XxxRename::Data::SceneData do
  let(:female_actors) { %w[female_actor1 female_actor2] }
  let(:male_actors) { %w[male_actor1 male_actor2] }
  let(:actors) { female_actors + male_actors }
  let(:title) { "title" }
  let(:id) { "123" }
  let(:collection) { "collection" }
  let(:collection_tag) { "[CUSTOM_TAG]" }
  let(:date_released) { Time.parse("2013-12-08T00:00:00+00:00") }

  context "when optional data is not provided" do
    subject(:call) do
      described_class.new(
        title: title,
        collection: collection,
        actors: [],
        id: nil,
        date_released: nil
      )
    end

    it "should use default values" do
      expect(call.female_actors).to eq([])
      expect(call.male_actors).to eq([])
      expect(call.actors).to eq([])
      expect(call.collection).to eq(collection)
      expect(call.collection_tag).to eq("")
      expect(call.title).to eq(title)
      expect(call.id).to eq(nil)
      expect(call.date_released).to eq(nil)
    end
  end

  context "when all data is provided" do
    subject(:call) do
      described_class.new(
        female_actors: female_actors,
        male_actors: male_actors,
        actors: actors,
        title: title,
        id: id,
        collection: collection,
        collection_tag: collection_tag,
        date_released: date_released
      )
    end

    it "should use default values" do
      expect(call.female_actors).to eq(female_actors)
      expect(call.male_actors).to eq(male_actors)
      expect(call.actors).to eq(%w[female_actor1 female_actor2 male_actor1 male_actor2])
      expect(call.collection).to eq(collection)
      expect(call.collection_tag).to eq(collection_tag)
      expect(call.title).to eq(title)
      expect(call.id).to eq(id)
      expect(call.date_released).to eq(date_released)
    end
  end

  describe "date functions" do
    subject(:call) do
      described_class.new(
        title: title,
        actors: [],
        collection: collection,
        id: nil,
        date_released: date_released
      )
    end

    context "date is passed to the struct" do
      it "should return valid values for date operations" do
        expect(call.year).to eq("2013")
        expect(call.month).to eq("12")
        expect(call.day).to eq("08")
      end
    end

    context "date is not passed to the struct" do
      let(:date_released) { nil }

      it "date operations should return nil" do
        expect(call.year).to eq(nil)
        expect(call.month).to eq(nil)
        expect(call.day).to eq(nil)
      end
    end
  end
end
