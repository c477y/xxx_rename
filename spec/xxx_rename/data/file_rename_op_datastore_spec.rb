# frozen_string_literal: true

require "rspec"
require "xxx_rename/data/file_rename_op_datastore"
require "xxx_rename/data/file_rename_op"

describe XxxRename::Data::FileRenameOpDatastore do
  include_context "config provider"

  before { Timecop.freeze(Time.local(2022, "jan", 1, 0, 0, 0)) }
  after { Timecop.return }

  subject { data_store.create!(stub_scene_data, source_file, output_file, dir) }

  let(:data_store) { described_class.new(store, Mutex.new) }
  let(:store) { XxxRename::Data::OutputDatastore.new("test_folder").store }
  let(:dir) { File.join(Dir.pwd, "test_folder") }
  let(:source_file) { "stub_scene.mp4" }
  let(:output_file) { "new_name_stub_scene.mp4" }

  describe ".create!" do
    context "when source file does not exist" do
      it "raises an error" do
        expect { subject }.to raise_error(XxxRename::Contract::FileRenameOpValidationFailure,
                                          /file_not_found: .*test_folder\/stub_scene.mp4/)
      end
    end

    context "when directory does not exist" do
      let(:dir) { "invalid_directory" }

      it "raises an error" do
        expect { subject }.to raise_error(XxxRename::Contract::FileRenameOpValidationFailure,
                                          "directory_not_exists: invalid_directory, non_absolute_path: invalid_directory")
      end
    end

    context "when a file exists with same name as output" do
      before do
        Dir.chdir(dir) do
          FileUtils.touch(source_file)
          FileUtils.touch(output_file)
        end
      end
      after do
        Dir.chdir(dir) do
          FileUtils.rm(source_file)
          FileUtils.rm(output_file)
        end
      end

      it "raises an error" do
        expect { subject }.to raise_error(XxxRename::Contract::FileRenameOpValidationFailure,
                                          /output_file_already_exists: .*test_folder\/new_name_stub_scene.mp4/)
      end
    end

    context "when output filename is more than 255 characters" do
      let(:output_file) { "#{"a" * 255}.mp4" }

      it "raises an error" do
        expect { subject }.to raise_error(XxxRename::Contract::FileRenameOpValidationFailure, /output_filename_too_long/)
      end
    end

    context "with valid parameters" do
      before { Dir.chdir(dir) { FileUtils.touch(source_file) } }
      after { Dir.chdir(dir) { FileUtils.rm(source_file) } }

      let(:expected_obj) do
        XxxRename::Data::FileRenameOp.new(
          {
            key: stub_scene_data.key,
            directory: dir,
            source_filename: source_file,
            output_filename: output_file,
            mtime: stub_scene_data.date_released
          }
        )
      end

      it "should add an entry to the datastore" do
        subject

        store.transaction(true) do
          expect(store[XxxRename::Data::OUTPUT_KEY]).to eq([expected_obj])
        end
      end
    end
  end
end
