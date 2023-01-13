# frozen_string_literal: true

require "rspec"
require "xxx_rename/actions/resolver"

describe XxxRename::Actions::Resolver do
  subject(:resolver) { described_class.new(config) }

  let(:post_movie_to_stash_double) { instance_double("XxxRename::Actions::StashAppPostMovie") }
  let(:log_rename_op_double) { instance_double("XxxRename::Actions::LogNewFilename") }

  let(:config) { double("config") }

  context "with valid action 'sync_to_stash'" do
    let(:action) { "sync_to_stash" }
    before { expect(XxxRename::Actions::StashAppPostMovie).to receive(:new).with(config).and_return(post_movie_to_stash_double) }

    it "returns the expected action" do
      expect(resolver.resolve!(action)).to eq(post_movie_to_stash_double)
    end
  end

  context "with valid action :sync_to_stash" do
    let(:action) { :sync_to_stash }
    before { expect(XxxRename::Actions::StashAppPostMovie).to receive(:new).with(config).and_return(post_movie_to_stash_double) }

    it "returns the expected action" do
      expect(resolver.resolve!(action)).to eq(post_movie_to_stash_double)
    end
  end

  context "with invalid action" do
    let(:action) { :xyz }

    it "raises error" do
      expect { resolver.resolve!(action) }.to raise_error(XxxRename::Errors::FatalError, "Unknown action xyz")
    end
  end
end
