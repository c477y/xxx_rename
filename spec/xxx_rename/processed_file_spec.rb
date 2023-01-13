# frozen_string_literal: true

require "rspec"

describe XxxRename::ProcessedFile do
  include_context "config provider"

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

  before do
    allow(File).to receive(:mtime).and_return(Time.new(2020, 12, 12))
  end

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

      let(:file_name) { "Making A Splash [C] [F] Violet Starr [M] -.mp4" }
      let(:pattern) { "%title [%collection_tag_1]%collection_op [F]%female_actors [M]%male_actors_op -%id_op" }

      it_behaves_like "a valid file"
    end

    context "given a correct pattern with prefix tokens when prefix tokens are not initialised" do
      let(:file_name) { "Making A Splash [C] [F] Violet Starr [M] Isiah Maxwell [ID] 9999.mp4" }
      let(:pattern) do
        "%title [%collection_tag_1] %collection_op %female_actors_prefix %female_actors %male_actors_prefix %male_actors %id_prefix %id"
      end

      it "should raise error" do
        expect { parameter_reader }
          .to raise_error(ArgumentError, "Invalid tokens %female_actors_prefix, %male_actors_prefix, %id_prefix in pattern.")
      end
    end

    context "given an incorrect pattern 1" do
      let(:female) { female1 }
      let(:male) { male1 }
      let(:actors) { [] }

      let(:file_name) { "Making A Splash [F] Violet Starr, Amber Jade.mp4" }
      let(:pattern) { "%title [%collection_tag_2] %collection [F] %female_actors" }

      it "should raise error" do
        expect { parameter_reader }.to raise_error(XxxRename::Errors::ParsingError, /does not match given pattern/)
      end
    end
  end

  describe "#parse" do
    subject(:parameter_reader) { described_class.parse(file_name) }

    context "when passed a file name with single actors" do
      let(:file_name) { "Making A Splash [C] Baby Got Boobs [F] Violet Starr [M] Isiah Maxwell.mp4" }
      let(:female) { female1 }
      let(:male) { male1 }
      let(:actors) { (female1 + male1).flatten }

      it_behaves_like "a valid file"
    end

    context "when passed a file name with multiple female actors" do
      let(:file_name) { "Making A Splash [C] Baby Got Boobs [F] Giselle Palmer, Sheridan Love [M] Kyle Mason.mp4" }
      let(:female) { ["Giselle Palmer", "Sheridan Love"] }
      let(:male) { ["Kyle Mason"] }
      let(:actors) { (female + male).flatten }

      it_behaves_like "a valid file"
    end

    context "when passed a file name with title containing special characters" do
      let(:file_name) do
        "BRAZZERS LIVE 20 ALL-STARS [F] April O'Neil, Lexi Swallow, Madison Ivy, " \
        "Rachel Roxxx, Samantha Saint [M] Marco Banderas, Ramon Nomar, Tommy Gunn.mp4"
      end

      let(:female) do
        ["April O'Neil", "Lexi Swallow", "Madison Ivy", "Rachel Roxxx", "Samantha Saint"]
      end
      let(:male) { ["Marco Banderas", "Ramon Nomar", "Tommy Gunn"] }
      let(:actors) { (female + male).flatten }
      let(:title) { "BRAZZERS LIVE 20 ALL-STARS" }
      let(:collection) { "" }
      let(:collection_tag) { "" }

      it_behaves_like "a valid file"
    end

    context "when passed a file name with no male actors" do
      let(:file_name) { "Lapdancer's Last Laugh [C] Hot And Mean [F] Madison Ivy, Monique Alexander.mp4" }
      let(:female) { ["Madison Ivy", "Monique Alexander"] }
      let(:male) { [] }
      let(:actors) { (female + male).flatten }
      let(:title) { "Lapdancer's Last Laugh" }
      let(:collection) { "Hot And Mean" }

      it_behaves_like "a valid file"
    end

    context "when passed a file name with no collection" do
      let(:file_name) { "My Hot Boss [F] Lena Paul [M] JMac.mp4" }
      let(:female) { ["Lena Paul"] }
      let(:male) { ["JMac"] }
      let(:actors) { (female + male).flatten }
      let(:title) { "My Hot Boss" }
      let(:collection) { "" }
      let(:collection_tag) { "" }

      it_behaves_like "a valid file"
    end

    context "when passed an invalid file name" do
      let(:file_name) { "baby-got-boobs-blindfolded-surprise-12-05-2007.mp4" }

      it "returns correct attributes" do
        expect { parameter_reader.match? }.to raise_error("does not match any registered patterns")
      end
    end
  end

  describe "prefix tags are initialised" do
    before { described_class.prefix_hash_set(config.prefix_hash) }

    context "with default prefix tags" do
      let(:expected_map) do
        {
          "%actors_prefix" => "(?<actors_prefix>\\[A\\])",
          "%female_actors_prefix" => "(?<female_actors_prefix>\\[F\\])",
          "%male_actors_prefix" => "(?<male_actors_prefix>\\[M\\])",
          "%id_prefix" => "(?<id_prefix>\\[ID\\])",
          "%title_prefix" => "(?<title_prefix>\\[T\\])"
        }
      end

      it "sets the instance variable correctly" do
        expect(described_class.prefix_regex_maps).to eq(expected_map)
      end
    end

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
