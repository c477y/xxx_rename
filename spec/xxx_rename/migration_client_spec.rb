# frozen_string_literal: true

require "rspec"
require "xxx_rename/migration_client"

describe XxxRename::MigrationClient do
  include_context "config provider"
  include_context "stubs provider"

  describe ".version_file!" do
    subject(:version_file!) { described_class.new(config, version).version_file! }

    let(:version) { "latest" }
    let(:time1) { Timecop.freeze(Time.local(2022, "jan", 1, 0, 0, 0)) { Time.now.strftime("%Y%m%d%H%M").to_s } }
    let(:time2) { Timecop.freeze(Time.local(2023, "jan", 1, 0, 0, 0)) { Time.now.strftime("%Y%m%d%H%M").to_s } }
    let(:time3) { Timecop.freeze(Time.local(2023, "jan", 1, 0, 0, 1)) { Time.now.strftime("%Y%m%d%H%M").to_s } }
    let(:file1) { "output_#{time1}.yml" }
    let(:file2) { "output_#{time2}.yml" }
    let(:file3) { "output_#{time3}.yml" }

    context "when no version file exists" do
      it "should raise an error" do
        expect { version_file! }.to raise_error(XxxRename::Errors::FatalError, "[ERR NO MIGRATION FILES FOUND]")
      end
    end

    def create_files(*files)
      dir = File.join("test_folder", ".config", "xxx_rename", "generated", "output")
      files.each { |f| Dir.chdir(dir) { FileUtils.touch(f) } }
    end

    context "when a single migration file exists" do
      before { create_files(file1) }

      context "when version is 'latest'" do
        it { is_expected.to include(file1) }
      end

      context "version is same as file" do
        let(:version) { time1 }

        it { is_expected.to include(file1) }
      end
    end

    context "when multiple migration files exist" do
      before { create_files(file1, file2, file3) }

      context "when version is 'latest'" do
        it { is_expected.to include(file3) }
      end

      context "version is matches file1" do
        let(:version) { time1 }

        it { is_expected.to include(file1) }
      end

      context "version is matches file2" do
        let(:version) { time2 }

        it { is_expected.to include(file2) }
      end

      context "version is matches file3" do
        let(:version) { time3 }

        it { is_expected.to include(file3) }
      end

      context "when version does not match any file" do
        let(:version) { "202301131252" }

        it "raises an error" do
          expect { version_file! }.to raise_error(XxxRename::Errors::FatalError, "[ERR VERSION NOT EXIST] 202301131252")
        end
      end

      context "when version is some random string" do
        let(:version) { "random_string" }

        it "raises an error" do
          expect { version_file! }.to raise_error(XxxRename::Errors::FatalError, "[ERR VERSION NOT EXIST] random_string")
        end
      end
    end
  end

  describe ".apply" do
    subject(:client) { described_class.new(config, "latest") }
    let(:datastore) { client.datastore }

    let(:time) { Timecop.freeze(Time.local(2022, "jan", 1, 0, 0, 0)) { Time.now.strftime("%Y%m%d%H%M").to_s } }
    let(:file) { File.join("test_folder", ".config", "xxx_rename", "generated", "output", "output_#{time}.yml") }
    let(:source_file) { "foo.mp4" }
    let(:output_file) { "bar.mp4" }
    let(:directory) { File.join(Dir.pwd, "test_folder") }

    let(:scene_data) { stub_scene_data }

    before do
      expect(client).to receive(:version_file!).and_return(file)
      FileUtils.touch(File.join("test_folder", source_file))
      datastore.migration_status = 0
      config.scene_datastore.create!(scene_data)
      config.scene_datastore.register_file(scene_data, File.join(Dir.pwd, "test_folder", source_file))
      datastore.create!(scene_data, source_file, output_file, directory)
    end

    context "with valid contents" do
      before { client.apply }

      it "should rename the file" do
        Dir.chdir("test_folder") { expect(Dir["*.mp4"]).to eq([output_file]) }
      end

      it "migration should be up" do
        expect(datastore.migration_status).to be true
      end

      it "scene datastore should register the new filename" do
        old_path = File.join(Dir.pwd, "test_folder", source_file)
        expect(config.scene_datastore.find_by_abs_path?(old_path)).to be nil

        new_path = File.join(Dir.pwd, "test_folder", output_file)
        expect(config.scene_datastore.find_by_abs_path?(new_path)).to eq(scene_data)
      end

      it "does not add any errors to the migration file" do
        expect(datastore.failures).to eq({})
      end
    end

    context "error scenarios" do
      context "when migration is already applied" do
        before do
          datastore.migration_status = 1
          client.apply
        end

        it "should not rename the file" do
          Dir.chdir("test_folder") { expect(Dir["*.mp4"]).to eq([source_file]) }
        end
      end

      context "when source file is deleted" do
        before do
          FileUtils.rm(File.join("test_folder", source_file))
          client.apply
        end

        let(:expected_error) do
          {
            "369bbf2e50c5ac253de70eafc43a990d" => "No such file or directory @ rb_file_s_rename - (foo.mp4, bar.mp4)"
          }
        end

        it "migration should remain down" do
          expect(datastore.migration_status).to be false
        end

        it "migration should have recorded an error" do
          expect(datastore.failures).to eq(expected_error)
        end
      end
    end
  end

  describe ".rollback" do
    subject(:client) { described_class.new(config, "latest") }
    let(:datastore) { client.datastore }

    let(:time) { Timecop.freeze(Time.local(2022, "jan", 1, 0, 0, 0)) { Time.now.strftime("%Y%m%d%H%M").to_s } }
    let(:file) { File.join("test_folder", ".config", "xxx_rename", "generated", "output", "output_#{time}.yml") }
    let(:source_file) { "foo.mp4" }
    let(:output_file) { "bar.mp4" }
    let(:directory) { File.join(Dir.pwd, "test_folder") }

    let(:scene_data) { stub_scene_data }

    before do
      # Apply a migration first
      expect(client).to receive(:version_file!).and_return(file)
      FileUtils.touch(File.join("test_folder", source_file))
      datastore.migration_status = 0
      config.scene_datastore.create!(scene_data)
      config.scene_datastore.register_file(scene_data, File.join(Dir.pwd, "test_folder", source_file))
      datastore.create!(scene_data, source_file, output_file, directory)
      client.apply
    end

    context "with valid contents" do
      before { client.rollback }

      it "should rename the file back to original" do
        Dir.chdir("test_folder") { expect(Dir["*.mp4"]).to eq([source_file]) }
      end

      it "migration should be set back to down" do
        expect(datastore.migration_status).to be false
      end

      it "scene datastore should register the old filename" do
        new_path = File.join(Dir.pwd, "test_folder", output_file)
        expect(config.scene_datastore.find_by_abs_path?(new_path)).to be nil

        old_path = File.join(Dir.pwd, "test_folder", source_file)
        expect(config.scene_datastore.find_by_abs_path?(old_path)).to eq(scene_data)
      end

      it "does not add any errors to the migration file" do
        expect(datastore.failures).to eq({})
      end
    end

    context "error scenarios" do
      context "when migration is already down" do
        before do
          client.rollback
        end

        it "should not rename the file" do
          Dir.chdir("test_folder") { expect(Dir["*.mp4"]).to eq([source_file]) }
        end
      end

      context "when destination file is deleted after migration" do
        before do
          client.apply
          FileUtils.rm(File.join("test_folder", output_file))
          client.rollback
        end

        let(:expected_error) do
          {
            "369bbf2e50c5ac253de70eafc43a990d" => "No such file or directory @ rb_file_s_rename - (bar.mp4, foo.mp4)"
          }
        end

        it "migration should remain up" do
          expect(datastore.migration_status).to be true
        end

        it "migration should have recorded an error" do
          expect(datastore.failures).to eq(expected_error)
        end
      end
    end
  end
end
