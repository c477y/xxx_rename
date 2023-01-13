# frozen_string_literal: true

require "rspec"
require "xxx_rename/actions/log_new_filename"
require "xxx_rename/site_clients/brazzers"

describe XxxRename::Actions::LogNewFilename do
  subject(:perform) { action.perform(dir, file, search_result) }
  let(:action) { described_class.new(config) }
  let(:output_recorder) { config.output_recorder }

  include_context "config provider" do
    let(:override_config) do
      {
        "global" => {
          "output_format" => [
            "%id %title_prefix %title",
            "%id %female_actors_prefix %female_actors"
          ],
          "site" => {
            "brazzers" => {
              "output_format" => [
                "%yyyy_mm_dd %title_prefix %title"
              ]
            }
          }
        }
      }
    end
  end

  let(:dir) { nil }
  let(:file) { "foo_bar.mp4" }
  let(:search_result) do
    instance_double("XxxRename::Search::SearchResult",
                    { scene_data: scene_data,
                      site_client: site_client })
  end

  let(:site_client) { XxxRename::SiteClients::Brazzers.new(config) }

  let(:female_actor) { "female-actor" }
  let(:male_actor) { "male-actor" }
  let(:collection) { "collection" }
  let(:ctag) { "ct" }
  let(:title) { "scene-title" }
  let(:date) { Time.parse("2013-12-08T00:00:00+00:00") }
  let(:id) { "9999" }

  let(:scene_data) do
    XxxRename::Data::SceneData.new(
      female_actors: [female_actor],
      male_actors: [male_actor],
      actors: [female_actor, male_actor],
      collection: collection,
      collection_tag: ctag,
      title: title,
      id: id,
      date_released: date
    )
  end

  context "with valid params" do
    let(:pathname) { instance_double("Pathname") }

    before do
      expect(Dir).to receive(:pwd).and_return("test_folder")
      expect(Pathname).to receive(:new).and_return(pathname)
      expect(pathname).to receive(:absolute?).and_return(true)
      FileUtils.touch(File.join("test_folder", file))
      perform
    end

    let(:expected_log) do
      XxxRename::Data::FileRenameOp.new(
        key: scene_data.key,
        directory: "test_folder",
        source_filename: file,
        output_filename: "9999 [T] scene-title.mp4",
        mtime: date
      )
    end

    it "creates a rename operation in the datastore", :aggregate_failures do
      expect(output_recorder.length).to eq(1)
      expect(output_recorder.all.first).to eq(expected_log)
    end
  end

  context "when create! raises a validation error because source file does not exist" do
    before { perform }

    it "does not creates a rename operation" do
      expect(output_recorder.length).to eq(0)
    end
  end

  context "when filename generation fails due to missing mandatory token" do
    let(:id) { nil }
    let(:date) { nil }

    it "does not creates a rename operation" do
      expect(output_recorder.length).to eq(0)
    end
  end
end
