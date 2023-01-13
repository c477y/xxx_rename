# frozen_string_literal: true

require "rspec"

class UtilsTest
  include XxxRename::Utils
end

describe UtilsTest do
  describe "#adjust_apostrophe" do
    subject(:call) { described_class.new.adjust_apostrophe(arr) }
    context "given an array of strings" do
      let(:arr) { %w[ain t i ll i ve i m] }
      it "should return a single string with the apostrophe " do
        expect(call).to eq("ain't i'll i've i'm")
      end
    end
  end
end
