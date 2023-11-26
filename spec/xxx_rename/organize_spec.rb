# frozen_string_literal: true

require "rspec"
require "xxx_rename/organize"

describe XxxRename::Organize do
  describe "gather_stats" do
    include_context "config provider"
    include_context "stubs provider"

    subject(:stats) { organizer.gather_stats }
    let(:organizer) { described_class.new(config, source_dir: source_dir, destination_dir: destination_dir, force: force) }
    let(:force) { false }
    let(:source_dir) { create_dir("source") }
    let(:destination_dir) { create_dir("destination") }

    context "when there are no files in the source directory" do
      it "returns an empty hash" do
        expect(stats).to eq({})
      end
    end

    context "when source files are stored in datastore" do
      let(:file) { create_file(source_dir, "file.mp4") }
      let(:expected) { { "Foo Bar" => 1, "Baz Qux" => 1 } }

      before do
        config.scene_datastore.create!(stub_scene_data)
        config.scene_datastore.register_file(stub_scene_data, File.expand_path(file))
        stub_scene_data.female_actors.each { |actor| config.actors_datastore.create!(actor, "female") }
      end

      it "returns a hash with the actor and the number of scenes" do
        expect(stats).to eq(expected)
      end
    end

    context "when source files not organised and have no actor names" do
      let(:file) { create_file(source_dir, "file.mp4") }

      it "returns an empty hash" do
        expect(stats).to eq({})
      end
    end

    context "when source files not organised and force is enabled" do
      let(:force) { true }
      let!(:file) { create_file(source_dir, "file - Foo Bar, Baz Qux.mp4") }

      context "when actor names are stored" do
        before { stub_scene_data.female_actors.each { |actor| config.actors_datastore.create!(actor, "female") } }

        let(:expected) { { "Foo Bar" => 1, "Baz Qux" => 1 } }

        it "returns a hash with the actor and the number of scenes" do
          expect(stats).to eq(expected)
        end
      end

      context "when actor names are not stored" do
        it "returns an empty hash" do
          expect(stats).to eq({})
        end
      end
    end
  end

  describe "#organize" do
    include_context "config provider"
    include_context "stubs provider"

    subject(:organize) { organizer.organize(dry_run, minimum_scenes_threshold) }
    let(:organizer) { described_class.new(config, source_dir: source_dir, destination_dir: destination_dir, force: false) }
    let(:source_dir) { create_dir("source") }
    let(:destination_dir) { create_dir("destination") }

    let(:file1) { create_file(source_dir, "file1.mp4") }
    let(:file2) { create_file(source_dir, "file2.mp4") }

    shared_context "setup files" do
      before do
        # scene 1
        config.scene_datastore.create!(stub_scene_data)
        config.scene_datastore.register_file(stub_scene_data, File.expand_path(file1))
        stub_scene_data.female_actors.each { |actor| config.actors_datastore.create!(actor, "female") }

        # scene 2
        config.scene_datastore.create!(stub_scene_data2)
        config.scene_datastore.register_file(stub_scene_data2, File.expand_path(file2))
        stub_scene_data2.female_actors.each { |actor| config.actors_datastore.create!(actor, "female") }

        # gather the stats
        organizer.gather_stats
      end
    end

    context "with dry run disabled" do
      let(:dry_run) { false }
      include_context "setup files"

      context "when minimum scenes threshold is 0" do
        let(:minimum_scenes_threshold) { 0 }

        it "creates new directories" do
          organize

          expect(File.directory?(File.join(destination_dir, "Foo Bar"))).to be_truthy
          expect(File.directory?(File.join(destination_dir, "Lorem ipsum"))).to be_truthy
        end

        it "moves the files" do
          organize

          expect(File.exist?(File.join(destination_dir, "Foo Bar", "file1.mp4"))).to be_truthy
          expect(File.exist?(File.join(destination_dir, "Lorem ipsum", "file2.mp4"))).to be_truthy
        end

        context "scene datastore update" do
          before { organize }

          let(:new_file1_path) { File.expand_path(File.join(destination_dir, "Foo Bar", "file1.mp4")) }
          let(:new_file2_path) { File.expand_path(File.join(destination_dir, "Lorem ipsum", "file2.mp4")) }

          it "updates the scene datastore", :aggregate_failures do
            # old paths are set to nil
            expect(config.scene_datastore.find_by_abs_path?(File.expand_path(file1))).to be_nil
            expect(config.scene_datastore.find_by_abs_path?(File.expand_path(file2))).to be_nil

            # new paths are set
            expect(config.scene_datastore.find_by_abs_path?(new_file1_path)).to eq(stub_scene_data)
            expect(config.scene_datastore.find_by_abs_path?(new_file2_path)).to eq(stub_scene_data2)

            # find by basename should still work
            expect(config.scene_datastore.find_by_base_filename?(File.basename(file1))).to eq([stub_scene_data])
            expect(config.scene_datastore.find_by_base_filename?(File.basename(file2))).to eq([stub_scene_data2])
          end
        end
      end
    end

    context "with dry run enabled" do
      let(:dry_run) { true }
      include_context "setup files"

      context "when minimum scenes threshold is 0" do
        let(:minimum_scenes_threshold) { 0 }

        it "does not create new directories" do
          organize

          expect(File.directory?(File.join(destination_dir, "Foo Bar"))).to be_falsey
          expect(File.directory?(File.join(destination_dir, "Lorem ipsum"))).to be_falsey
        end

        it "does not move the files" do
          organize

          expect(File.exist?(File.join(destination_dir, "Foo Bar", "file1.mp4"))).to be_falsey
          expect(File.exist?(File.join(destination_dir, "Lorem ipsum", "file2.mp4"))).to be_falsey
        end

        context "scene datastore update" do
          before { organize }

          it "does not update the scene datastore", :aggregate_failures do
            expect(config.scene_datastore.find_by_abs_path?(File.expand_path(file1))).to eq(stub_scene_data)
            expect(config.scene_datastore.find_by_abs_path?(File.expand_path(file2))).to eq(stub_scene_data2)
          end
        end
      end
    end

    context "when minimum scenes threshold is 5" do
      let(:minimum_scenes_threshold) { 5 }
      let(:dry_run) { false }

      include_context "setup files"

      it "does not create new directories" do
        organize

        expect(File.directory?(File.join(destination_dir, "Foo Bar"))).to be_falsey
        expect(File.directory?(File.join(destination_dir, "Lorem ipsum"))).to be_falsey
      end

      it "does not move the files" do
        organize

        expect(File.exist?(File.join(destination_dir, "Foo Bar", "file1.mp4"))).to be_falsey
        expect(File.exist?(File.join(destination_dir, "Lorem ipsum", "file2.mp4"))).to be_falsey
      end
    end

    context "when the destination directory already exists" do
      let(:dry_run) { false }
      let(:minimum_scenes_threshold) { 0 }

      include_context "setup files"

      before do
        Dir.mkdir(File.join(destination_dir, "Foo Bar"))
        Dir.mkdir(File.join(destination_dir, "Lorem ipsum"))
      end

      it "moves the files" do
        organize

        expect(File.exist?(File.join(destination_dir, "Foo Bar", "file1.mp4"))).to be_truthy
        expect(File.exist?(File.join(destination_dir, "Lorem ipsum", "file2.mp4"))).to be_truthy
      end
    end

    context "when a scene has no primary actor" do
      let(:dry_run) { false }
      let(:minimum_scenes_threshold) { 0 }

      it "does not move the source file" do
        expect { organize }.not_to(change { File.exist?(File.join(destination_dir, "Foo Bar", "file1.mp4")) })
      end
    end
  end
end
