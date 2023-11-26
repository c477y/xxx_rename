# frozen_string_literal: true

require "rspec"
require "xxx_rename/data/stats_hash"

describe XxxRename::Data::StatsHash do
  subject(:stats) { described_class.new }

  context "when a file is stored" do
    let(:file) { "file.mp4" }
    let(:actors) { ["Foo Bar", "Baz Qux"] }

    before { stats.increment(file, actors) }

    it "returns the primary actor" do
      expect(stats.primary_actor(file)).to eq("Foo Bar")
    end

    it "returns the scene count for an actor" do
      expect(stats.scene_count("Foo Bar")).to eq(1)
    end

    it "returns the statistics" do
      expect(stats.statistics).to eq("Foo Bar" => 1, "Baz Qux" => 1)
    end
  end

  context "when multiple files are stored" do
    let(:file1) { "file1.mp4" }
    let(:file2) { "file2.mp4" }
    let(:file3) { "file3.mp4" }

    let(:actors1) { ["Foo Bar", "Baz Qux"] }
    let(:actors2) { ["Quux Corge", "Grault Garply", "Foo Bar"] }
    let(:actors3) { ["Waldo Fred", "Foo Bar"] }

    before do
      stats.increment(file1, actors1)
      stats.increment(file2, actors2)
      stats.increment(file3, actors3)
    end

    it "returns the primary actor for file1" do
      expect(stats.primary_actor(file1)).to eq("Foo Bar")
    end

    it "returns the primary actor for file2" do
      expect(stats.primary_actor(file2)).to eq("Foo Bar")
    end

    it "returns the primary actor for file3" do
      expect(stats.primary_actor(file3)).to eq("Foo Bar")
    end

    it "returns the scene count for all actor" do
      expect(stats.scene_count("Foo Bar")).to eq(3)
      expect(stats.scene_count("Baz Qux")).to eq(1)
      expect(stats.scene_count("Grault Garply")).to eq(1)
    end

    it "returns the statistics" do
      expect(stats.statistics).to eq("Foo Bar" => 3, "Waldo Fred" => 1, "Grault Garply" => 1, "Quux Corge" => 1, "Baz Qux" => 1)
    end
  end

  context "when a file is stored with no actors" do
    let(:file) { "file.mp4" }
    let(:actors) { [] }

    it "should raise an ArgumentError" do
      expect { stats.increment(file, actors) }.to raise_error(ArgumentError, "File should have at least one actor")
    end
  end

  context "when primary actor is accessed without storing it first" do
    let(:file) { "file.mp4" }

    it "should raise an ArgumentError" do
      expect { stats.primary_actor(file) }.to raise_error(ArgumentError, "File not registered in statistics")
    end
  end

  describe "#statistics" do
    before do
      stats.increment("file1", ["Foo Bar", "Baz Qux"])
      stats.increment("file2", ["Quux Corge", "Grault Garply", "Foo Bar"])
      stats.increment("file3", ["Waldo Fred", "Foo Bar"])
    end

    let(:expected_statistics) do
      {
        "Foo Bar" => 3,
        "Waldo Fred" => 1,
        "Grault Garply" => 1,
        "Quux Corge" => 1,
        "Baz Qux" => 1
      }
    end

    it "returns the statistics" do
      expect(stats.statistics).to eq(expected_statistics)
    end
  end
end
