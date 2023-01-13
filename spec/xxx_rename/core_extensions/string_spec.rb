# frozen_string_literal: true

require "rspec"

class StringTest
  include XxxRename::CoreExtensions::String
end

describe StringTest do
  # describe "#normalize" do
  #   subject(:call) { described_class.new.normalize(str) }
  #   context "given a string with whitespaces" do
  #     let(:str) { "Tan That Ass" }
  #     it "should remove all special and whitescpace characters from string" do
  #       expect(call).to eq("tanthatass")
  #     end
  #   end
  #
  #   context "given a string with special characters" do
  #     let(:str) { "Tan 121Y@#&%^$&*%_+_" }
  #     it "should remove all special and whitescpace characters from string" do
  #       expect(call).to eq("tan121y")
  #     end
  #   end
  # end
  # describe "#remove_special_characters" do
  #   subject(:call) { described_class.new.remove_special_characters(str) }
  #   context "given a string with special characters" do
  #     let(:str) { "Anal +=Corruption& 03 [EA] Anal & Corruption ?        0|3 [F] \\Abella Danger:;,<> Keisha Grey" }
  #     let(:correct_str) { "Anal Corruption 03 [EA] Anal Corruption 03 [F] Abella Danger, Keisha Grey" }
  #     it "should return correct result" do
  #       expect(call).to eq(correct_str)
  #     end
  #   end
  # end
end
