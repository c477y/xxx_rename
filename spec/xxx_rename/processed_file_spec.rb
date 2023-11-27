# frozen_string_literal: true

require "rspec"

describe XxxRename::ProcessedFile do
  include_context "config provider" do
    let(:override_config) { override }
  end
  let(:override) { {} }

  RSpec.shared_examples "a valid file" do
    it "returns correct attributes" do
      expect(parameter_reader.female_actors).to eq(female)
      expect(parameter_reader.male_actors).to eq(male)
      expect(parameter_reader.actors).to eq(actors)
      expect(parameter_reader.title).to eq(title)
      expect(parameter_reader.collection).to eq(collection)
      expect(parameter_reader.collection_tag).to eq(collection_tag)
      expect(parameter_reader.id).to eq(id)
    end
  end

  let(:female1) { ["Violet Starr"] }
  let(:female2) { ["Amber Jade"] }
  let(:actors) { [] }
  let(:male1) { ["Isiah Maxwell"] }
  let(:title) { "Making A Splash" }
  let(:collection) { "Baby Got Boobs" }
  let(:collection_tag) { "C" }
  let(:id) { nil }

  describe "#strpfile" do
    subject(:parameter_reader) { described_class.strpfile(file_name, pattern) }

    context "given a correct pattern 1" do
      let(:female) { female1 }
      let(:male) { male1 }
      let(:actors) { (female1 + male1).flatten }

      let(:file_name) { "Making A Splash [C] Baby Got Boobs [F] Violet Starr [M] Isiah Maxwell.mp4" }
      let(:pattern) { "%title [%collection_tag_1] %collection [F] %female_actors [M] %male_actors" }

      it_behaves_like "a valid file"
    end

    context "given a correct pattern 2" do
      let(:female) { [] }
      let(:male) { [] }
      let(:actors) { (female1 + male1).sort }

      let(:file_name) { "Making A Splash [C] Baby Got Boobs [A] Violet Starr, Isiah Maxwell.mp4" }
      let(:pattern) { "%title [%collection_tag_1] %collection [A] %actors" }

      it_behaves_like "a valid file"
    end

    context "given a correct pattern 3" do
      let(:female) { (female1 + female2).sort }
      let(:male) { [] }
      let(:actors) { female }
      let(:collection_tag) { "BZ" }

      let(:file_name) { "Making A Splash [BZ] Baby Got Boobs [F] Violet Starr, Amber Jade.mp4" }
      let(:pattern) { "%title [%collection_tag_2] %collection [F] %female_actors" }

      it_behaves_like "a valid file"
    end

    context "given a correct pattern 4" do
      let(:female) { (female1 + female2).sort }
      let(:male) { [] }
      let(:actors) { female }
      let(:collection_tag) { "" }
      let(:collection) { "" }

      let(:file_name) { "Making A Splash [F] Violet Starr, Amber Jade.mp4" }
      let(:pattern) { "%title [F] %female_actors" }

      it_behaves_like "a valid file"
    end

    context "given a correct pattern with optional tag: %collection_op" do
      let(:female) { female1 }
      let(:male) { male1 }
      let(:actors) { (female1 + male1).flatten }
      let(:collection) { "" }
      let(:id) { "9999" }

      let(:file_name) { "9999 - Making A Splash [C] [F] Violet Starr [M] Isiah Maxwell.mp4" }
      let(:pattern) { "%id -%title [%collection_tag_1]%collection_op [F] %female_actors [M] %male_actors" }

      it_behaves_like "a valid file"
    end

    context "given a correct pattern with optional tag: %collection_op, #%male_actors_op, %id_op" do
      let(:female) { female1 }
      let(:male) { [] }
      let(:actors) { female1 }
      let(:collection) { "" }
      let(:id) { "" }

      let(:file_name) { "Making A Splash [C] [F] Violet Starr [M] -.mp4" }
      let(:pattern) { "%title [%collection_tag_1]%collection_op [F]%female_actors [M]%male_actors_op -%id_op" }

      it_behaves_like "a valid file"
    end

    context "given a file that has non-ASCII characters" do
      let(:female) { female1 }
      let(:male) { [] }
      let(:actors) { female1 }
      let(:collection) { "" }
      let(:id) { "" }

      let(:file_name) { "Making A Splash è èèè [C] 😶😶😶 [F] Violet 😶😶😶 Starr [M] 😶  😶  😶-.mp4" }
      let(:pattern) { "%title [%collection_tag_1]%collection_op [F]%female_actors [M]%male_actors_op -%id_op" }

      it_behaves_like "a valid file"
    end

    context "given a file that where the collection_prefix has to be overridden" do
      let(:override) do
        {
          "file_pre_process" => [
            "regex" => "GP",
            "with" => "ST"
          ]
        }
      end

      let(:female) { female1 }
      let(:male) { male1 }
      let(:actors) { (female1 + male1).flatten }
      let(:collection_tag) { "ST" }
      let(:file_name) { "Making A Splash [GP] Baby Got Boobs [F] Violet Starr [M] Isiah Maxwell.mp4" }
      let(:pattern) { "%title [%collection_tag_2] %collection [F] %female_actors [M] %male_actors" }

      it_behaves_like "a valid file"
    end

    context "given a file that has some random that that has to be ignored" do
      let(:override) do
        {
          "file_pre_process" => [
            "regex" => "\\[start.*$",
            "with" => ""
          ]
        }
      end

      let(:female) { female1 }
      let(:male) { male1 }
      let(:collection) { "" }
      let(:collection_tag) { "" }
      let(:actors) { (female1 + male1).flatten }
      let(:file_name) { "[F] Violet Starr [M] Isiah Maxwell [T] Making A Splash [start of some random text.mp4" }
      let(:pattern) { "%female_actors_prefix %female_actors %male_actors_prefix %male_actors %title_prefix %title" }

      it_behaves_like "a valid file"
    end

    context "given an incorrect pattern 1" do
      let(:female) { female1 }
      let(:male) { male1 }
      let(:actors) { [] }

      let(:file_name) { "Making A Splash [F] Violet Starr, Amber Jade.mp4" }
      let(:pattern) { "%title [%collection_tag_2] %collection [F] %female_actors" }

      it "should raise error" do
        expect { parameter_reader }.to raise_error(XxxRename::Errors::ParsingError)
      end
    end
  end

  describe "prefix tags are initialised" do
    before { described_class.prefix_hash_set(config.prefix_hash) }

    describe "#strpfile" do
      subject(:parameter_reader) { described_class.strpfile(file_name, pattern) }

      context "correct pattern: prefix tokens, female + male actors, id" do
        let(:file_name) { "Making A Splash [C] [F] Violet Starr [M] Isiah Maxwell [ID] 9999.mp4" }
        let(:pattern) do
          "%title [%collection_tag_1]%collection_op %female_actors_prefix %female_actors %male_actors_prefix %male_actors %id_prefix %id"
        end
        let(:female) { female1 }
        let(:male) { male1 }
        let(:actors) { (female1 + male1).flatten }
        let(:collection) { "" }
        let(:id) { "9999" }

        it_behaves_like "a valid file"
      end

      context "correct pattern: prefix tokens, actors, id, random chars" do
        let(:file_name) { "Making A Splash [C] Baby Got Boobs [A] Violet Starr, Isiah Maxwell [ID] ____9999.mp4" }
        let(:pattern) do
          "%title [%collection_tag_1]%collection_op %actors_prefix %actors %id_prefix ____%id"
        end
        let(:female) { [] }
        let(:male) { [] }
        let(:actors) { (female1 + male1).flatten.sort }
        let(:id) { "9999" }

        it_behaves_like "a valid file"
      end
    end
  end
end
