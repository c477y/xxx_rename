# frozen_string_literal: true

require "rspec"
require "xxx_rename/stash_app_client"

RSpec.describe XxxRename::StashAppClient, type: :stash_scraper do
  include_context "config provider" do
    let(:override_config) { { "stash_app" => { "url" => "localhost:9999" } } }
  end

  describe "scene_by_fragment" do
    subject(:scene_by_fragment) { described_class.new(config).scene_by_fragment }

    let(:title) { stub_scene_data.title }
    let(:filename1) { "file_name-1.mp4" }
    let(:filename1_path) { File.expand_path(File.join("test_folder", filename1)) }

    let(:input) do
      {
        "clientMutationId": nil,
        "id": "1",
        "title": title,
        "code": nil,
        "details": nil,
        "director": nil,
        "url": "",
        "date": nil,
        "rating": nil,
        "rating100": nil,
        "o_counter": nil,
        "organized": nil,
        "studio_id": nil,
        "gallery_ids": nil,
        "performer_ids": nil,
        "movies": nil,
        "tag_ids": nil,
        "cover_image": nil,
        "stash_ids": nil,
        "resume_time": nil,
        "play_duration": nil,
        "play_count": nil,
        "primary_file_id": nil
      }.to_json
    end

    let(:expected_output) do
      {
        title: "Awesome Title",
        code: "1234",
        date: "2020-01-10T00:00:00.000+00:00",
        urls: [],
        images: [],
        studio: { name: "Some Collection" },
        performers: [{ performer: { name: "Foo Bar", gender: "FEMALE" } },
                     { performer: { name: "Baz Qux", gender: "FEMALE" } },
                     { performer: { name: "Fred Thud", gender: "MALE" } }]
      }.to_json
    end

    before do
      allow($stdin).to receive(:gets) { input }
      StashStubs::StashApp.enable_version_stub
      StashStubs::StashApp.enable_scene_paths_by_id_stub(1, stub_scene_data.title, [filename1_path])
    end

    context "when scene datastore does not contain any matching scene data" do
      it "should not log anything to stdout" do
        expect { scene_by_fragment }.to output("").to_stdout
      end
    end

    context "when scene datastore is able to match the file by the filename" do
      before do
        FileUtils.touch(File.join("test_folder", filename1))
        config.scene_datastore.create!(stub_scene_data)
        config.scene_datastore.register_file(stub_scene_data, filename1_path)
      end

      it "should log the scene data to stdout" do
        expect { scene_by_fragment }.to output(expected_output).to_stdout
      end
    end
  end
end
