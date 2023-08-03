# frozen_string_literal: true

require "rspec"
require "xxx_rename/data/data_store_query_helper"
require "xxx_rename/data/scene_datastore"

RSpec.describe XxxRename::Data::DataStoreQueryHelper do
  describe ".find" do
    include_context "config provider"
    include_context "stubs provider"

    subject(:klass) { described_class.new(config.scene_datastore) }

    let(:find) { klass.find(scene_data, basename: basename, absolute_path: absolute_path) }

    context "when matching with absolute path is successful" do
      before do
        FileUtils.touch(File.join("test_folder", file))
        config.scene_datastore.create!(stub_scene_data)
        config.scene_datastore.register_file(stub_scene_data, absolute_path)
      end

      let(:file) { "file_name.mp4" }
      let(:absolute_path) { File.expand_path(File.join("test_folder", file)) }
      let(:basename) { nil }
      let(:scene_data) { nil }

      it "returns the scene data" do
        expect(find).to eq_scene_data(stub_scene_data)
      end
    end

    context "when matching with basename" do
      context "when single file exists in datastore with the given filename" do
        before do
          FileUtils.touch(File.join("test_folder", file))
          config.scene_datastore.create!(scene_data)
          config.scene_datastore.register_file(scene_data, absolute_path_file)
        end

        let(:file) { "file_name.mp4" }
        let(:absolute_path_file) { File.expand_path(File.join("test_folder", file)) }
        let(:absolute_path) { nil }
        let(:basename) { file }
        let(:scene_data) { stub_scene_data }

        it "returns the scene data" do
          expect(find).to eq_scene_data(scene_data)
        end
      end

      context "when multiple files exist in datastore with the given filename" do
        before do
          # Create two different files with the same name
          # File 1
          FileUtils.touch(File.join("test_folder", file))
          # File 2
          FileUtils.mkpath(File.join("test_folder", "nested_folder"))
          FileUtils.touch(File.join("test_folder", "nested_folder", file))

          # Store the first scene
          config.scene_datastore.create!(scene_data)
          config.scene_datastore.register_file(scene_data, absolute_path_file1)

          # Store the conflicting scene
          config.scene_datastore.create!(conflicting_scene_data)
          config.scene_datastore.register_file(conflicting_scene_data, absolute_path_file2)
        end

        let(:file) { "file_name.mp4" }
        let(:absolute_path_file1) { File.expand_path(File.join("test_folder", file)) }
        let(:absolute_path_file2) { File.expand_path(File.join("test_folder", "nested_folder", file)) }


        let(:basename) { file }
        let(:absolute_path) { nil }
        let(:scene_data) { stub_scene_data }
        let(:conflicting_scene_data) { stub_scene_data2 }

        it "returns the scene data" do
          expect(find).to eq_scene_data(scene_data)
        end
      end

      context "when there are scenes with the same basename but the scene data is different" do
        before do
          # Create two different files with the same name
          # File 1
          FileUtils.touch(File.join("test_folder", file))
          # File 2
          FileUtils.mkpath(File.join("test_folder", "nested_folder"))
          FileUtils.touch(File.join("test_folder", "nested_folder", file))

          # Store the scenes
          config.scene_datastore.create!(stub_scene_data2)
          config.scene_datastore.register_file(stub_scene_data2, absolute_path_file1)

          config.scene_datastore.create!(stub_scene_data3)
          config.scene_datastore.register_file(stub_scene_data3, absolute_path_file2)
        end

        let(:file) { "file_name.mp4" }
        let(:absolute_path_file1) { File.expand_path(File.join("test_folder", file)) }
        let(:absolute_path_file2) { File.expand_path(File.join("test_folder", "nested_folder", file)) }

        let(:basename) { file }
        let(:absolute_path) { nil }
        let(:scene_data) { stub_scene_data }

        it { expect(find).to be_nil }
      end
    end

    context "when matching with scene data parameters" do
      let(:basename) { nil }
      let(:absolute_path) { nil }
      let(:scene_data) { stub_scene_data }
      before(:each) { config.scene_datastore.create!(scene_data) }

      context "when matching with collection tag and id" do
        before do
          expect(klass).to receive(:find_by_abs_path).and_return(nil)
          expect(klass).to receive(:find_by_base_filename).and_return(nil)
        end

        it "returns the matching scene data" do
          expect(find).to eq_scene_data(scene_data)
        end
      end

      context "when matching with collection and title" do
        before do
          expect(klass).to receive(:find_by_abs_path).and_return(nil)
          expect(klass).to receive(:find_by_base_filename).and_return(nil)
          expect(klass).to receive(:find_by_collection_tag_and_id).and_return(nil)
          expect(klass).not_to receive(:find_by_actors_and_title)
        end

        it "returns the matching scene data" do
          expect(find).to eq_scene_data(scene_data)
        end
      end

      context "when matching with title and actors" do
        context "when only one scene exists with the given title and actors" do
          before do
            expect(klass).to receive(:find_by_abs_path).and_return(nil)
            expect(klass).to receive(:find_by_base_filename).and_return(nil)
            expect(klass).to receive(:find_by_collection_tag_and_id).and_return(nil)
            expect(klass).to receive(:find_by_collection_and_title).and_return(nil)
          end

          it "returns the matching scene data" do
            expect(find).to eq_scene_data(scene_data)
          end
        end

        context "when multiple scenes exist with the given title and actors" do
          let(:scene_data) do
            XxxRename::Data::SceneData.new(
              # Same attributes as scene_data
              female_actors: ["Foo Bar", "Baz Qux"],
              male_actors: ["Fred Thud"],
              actors: ["Baz Qux", "Foo Bar", "Fred Thud"],
              title: "Awesome Title",

              collection: collection,
              collection_tag: collection_tag,
              id: id,
              date_released: Time.local(2020, "jan", 10, 0, 0, 0)
            )
          end
          let(:conflicting_scene_data) { stub_scene_data }

          let(:collection) { "" }
          let(:collection_tag) { "" }
          let(:id) { "" }

          before do
            config.scene_datastore.create!(conflicting_scene_data)

            expect(klass).to receive(:find_by_abs_path).and_return(nil)
            expect(klass).to receive(:find_by_base_filename).and_return(nil)
            expect(klass).to receive(:find_by_collection_tag_and_id).and_return(nil)
            expect(klass).to receive(:find_by_collection_and_title).and_return(nil)
          end

          context "when conflict resolution is done via collection tag" do
            let(:collection_tag) { "AB" }

            it "returns the matching scene data" do
              expect(find).to eq_scene_data(scene_data)
            end
          end

          context "when conflict resolution is done via ID" do
            let(:id) { "5678" }

            it "returns the matching scene data" do
              expect(find).to eq_scene_data(scene_data)
            end
          end

          context "when conflict resolution is done via collection" do
            let(:collection) { "COLLECTION" }

            it "returns the matching scene data" do
              expect(find).to eq_scene_data(scene_data)
            end
          end

          context "when no conflict resolution is done" do
            it { expect(find).to be_nil }
          end
        end
      end
    end
  end
end
