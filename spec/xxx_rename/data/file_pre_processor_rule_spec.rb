# frozen_string_literal: true

require "rspec"
require "xxx_rename/data/file_pre_processor_rule"

RSpec.describe XxxRename::Data::FilePreProcessorRule do
  describe "replace" do
    subject(:replace) do
      described_class.new(rule).replace(file)
    end

    context "with default rule to replace non-ascii characters" do
      let(:rule) { described_class::DEFAULT_RULES.first }

      let(:file) { "text ééé al ééé" }

      it { expect(replace).to eq("text  al ") }
    end

    context "with default rule to replace double spaces" do
      let(:rule) { described_class::DEFAULT_RULES[1] }

      let(:file) { "text   text text   " }

      it { expect(replace).to eq("text text text ") }
    end
  end
end
