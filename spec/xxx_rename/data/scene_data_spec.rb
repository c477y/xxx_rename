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
        id: nil
      )
    end

    it "should use default values" do
      expect(call.female_actors).to eq([])
      expect(call.male_actors).to eq([])
      expect(call.actors).to eq([])
      expect(call.collection).to eq(collection)
      expect(call.collection_tag).to eq("")
      expect(call.title).to eq(title)
      expect(call.id).to eq("")
      expect(call.date_released).to eq(nil)
    end

    context "date is not passed to the struct" do
      it "date operations should return nil" do
        expect(call.year).to eq(nil)
        expect(call.month).to eq(nil)
        expect(call.day).to eq(nil)
      end
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
  end

  describe "match?" do
    subject { scene1.match?(scene2) }

    context "when scene2 is not of type SceneData" do
      let(:scene1) { described_class.new(title: "title") }
      let(:scene2) { "title" }

      it { expect { subject }.to raise_error(ArgumentError, "expected other to respond to .to_h") }
    end

    context "when scene data only has title" do
      let(:scene1) { described_class.new(title: title1) }
      let(:scene2) { described_class.new(title: title2) }

      context "when titles match" do
        let(:title1) { "title" }
        let(:title2) { "title" }

        it { is_expected.to eq(true) }
      end

      context "when titles do not match" do
        let(:title1) { "title" }
        let(:title2) { "xyz" }

        it { is_expected.to eq(false) }
      end
    end

    context "when scene data has title and date" do
      let(:scene1) { described_class.new(title: title1, date_released: date1) }
      let(:scene2) { described_class.new(title: title2, date_released: date2) }

      context "when titles and dates match" do
        let(:title1) { "title" }
        let(:title2) { "title" }
        let(:date1) { Time.strptime("2013-12-08", "%Y-%m-%d") }
        let(:date2) { Time.strptime("2013-12-08", "%Y-%m-%d") }

        it { is_expected.to eq(true) }
      end

      context "when titles match but dates do not match" do
        let(:title1) { "title" }
        let(:title2) { "title" }
        let(:date1) { Time.strptime("2013-12-08", "%Y-%m-%d") }
        let(:date2) { Time.strptime("2013-12-07", "%Y-%m-%d") }

        it { is_expected.to eq(false) }
      end

      context "when titles do not match but dates match" do
        let(:title1) { "title" }
        let(:title2) { "xyz" }
        let(:date1) { Time.strptime("2013-12-08", "%Y-%m-%d") }
        let(:date2) { Time.strptime("2013-12-08", "%Y-%m-%d") }

        it { is_expected.to eq(false) }
      end

      context "when scene1 has a time but scene2 does not" do
        let(:scene2) { described_class.new(title: title2) }

        let(:title1) { "title" }
        let(:title2) { "title" }
        let(:date1) { Time.strptime("2013-12-08", "%Y-%m-%d") }
        let(:date2) { nil }

        it { is_expected.to eq(true) }
      end
    end

    context "when scene data has title, actors and collection"  do
      let(:scene1) { described_class.new(title: title1, actors: actors1, collection: collection1) }
      let(:scene2) { described_class.new(title: title2, actors: actors2, collection: collection2) }

      context "when titles, actors and collections match" do
        let(:title1) { "title" }
        let(:title2) { "title" }
        let(:actors1) { %w[actor1 actor2] }
        let(:actors2) { %w[actor1 actor2] }
        let(:collection1) { "collection" }
        let(:collection2) { "collection" }

        it { is_expected.to eq(true) }
      end

      # collection match can cause false-negatives
      # context "when titles, actors and collections do not match" do
      #   let(:title1) { "title" }
      #   let(:title2) { "title2" }
      #   let(:actors1) { %w[actor1 actor2] }
      #   let(:actors2) { %w[actor1 actor2] }
      #   let(:collection1) { "collection" }
      #   let(:collection2) { "collection" }
      #
      #   it { is_expected.to eq(false) }
      # end
    end

    context "when scene data has title, actors, collection and date_released" do
      let(:scene1) { described_class.new(title: title1, actors: actors1, collection: collection1, date_released: date1) }
      let(:scene2) { described_class.new(title: title2, actors: actors2, collection: collection2, date_released: date2) }

      context "when titles, actors, collections and dates match" do
        let(:title1) { "title" }
        let(:title2) { "title" }
        let(:actors1) { %w[actor1 actor2] }
        let(:actors2) { %w[actor1 actor2] }
        let(:collection1) { "collection" }
        let(:collection2) { "collection" }
        let(:date1) { Time.strptime("2013-12-08", "%Y-%m-%d") }
        let(:date2) { Time.strptime("2013-12-08", "%Y-%m-%d") }

        it { is_expected.to eq(true) }
      end

      context "when none of the attributes match" do
        let(:title1) { "title" }
        let(:title2) { "title2" }
        let(:actors1) { %w[actor1 actor2] }
        let(:actors2) { %w[actor3 actor4] }
        let(:collection1) { "collection1" }
        let(:collection2) { "collection2" }
        let(:date1) { Time.strptime("2013-12-08", "%Y-%m-%d") }
        let(:date2) { Time.strptime("2013-12-07", "%Y-%m-%d") }

        it { is_expected.to eq(false) }
      end
    end
  end
end
