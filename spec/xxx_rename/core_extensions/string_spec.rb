# frozen_string_literal: true

require "rspec"

describe "String Test" do
  describe "#normalize" do
    subject(:call) { str.normalize }
    context "given a string with whitespaces" do
      let(:str) { "Tan That Ass" }
      it "should remove all special and white space characters from string" do
        expect(call).to eq("tanthatass")
      end
    end

    context "given a string with special characters" do
      let(:str) { "Tan 121Y@#&%^$&*%_+_" }
      it "should remove all special and white space characters from string" do
        expect(call).to eq("tan121y")
      end
    end
  end

  describe "#remove_special_characters" do
    subject(:call) { str.remove_special_characters }
    context "given a string with special characters" do
      let(:str) { "Anal +=Corruption& 03 [EA] Anal & Corruption ?        0|3 [F] \\Abella Danger:;,<> Keisha Grey" }
      let(:correct_str) { "Anal Corruption 03 [EA] Anal Corruption 03 [F] Abella Danger, Keisha Grey" }
      it "should return correct result" do
        expect(call).to eq(correct_str)
      end
    end
  end

  describe "#denormalize" do
    context "when normalized string is part of source string" do
      let(:str) { "tanthatass" }
      let(:source_str) { "Tan That Ass" }
      let(:expected) { source_str }

      it { expect(str.denormalize(source_str)).to eq(expected) }
    end

    context "when normalized string is in start of source string" do
      let(:str) { "bridgetteb" }
      let(:source_str) { "Bridgette B. - Some Scene name" }
      let(:expected) { "Bridgette B" }

      it { expect(str.denormalize(source_str)).to eq(expected) }
    end

    context "when normalized string is in end of source string" do
      let(:str) { "bridgetteb" }
      let(:source_str) { "Some Scene name - Bridgette B" }
      let(:expected) { "Bridgette B" }

      it { expect(str.denormalize(source_str)).to eq(expected) }
    end

    context "when normalized string is in middle of source string" do
      let(:str) { "bridgetteb" }
      let(:source_str) { "Some Scene name - Bridgette B, Ava Addams, Lee [X] Text" }
      let(:expected) { "Bridgette B" }

      it { expect(str.denormalize(source_str)).to eq(expected) }
    end

    context "when normalized string is not part of source string" do
      let(:str) { "bridgetteb" }
      let(:source_str) { "Bridgette - Some Scene name" }
      let(:expected) { nil }

      it { expect(str.denormalize(source_str)).to eq(expected) }
    end
  end
end
