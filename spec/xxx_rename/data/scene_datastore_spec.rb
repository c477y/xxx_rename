# frozen_string_literal: true

require "rspec"
require "xxx_rename/data/scene_datastore"
require "xxx_rename/data/site_client_meta_data"
require "xxx_rename/data/scene_data"

describe XxxRename::Data::SceneDatastoreQuery do
  include_context "config provider"

  subject(:data_store) { described_class.new(store, Mutex.new) }

  let(:store) { XxxRename::Data::SceneDatastore.new("test_folder").store }
  # scene 1
  let(:scene1) do
    XxxRename::Data::SceneData.new(
      female_actors: [female_actor1],
      male_actors: [male_actor1],
      actors: [female_actor1, male_actor1],
      collection: collection1,
      collection_tag: ctag1,
      title: title1,
      id: id1,
      date_released: date
    )
  end
  let(:female_actor1) { "female-actor-1" }
  let(:male_actor1) { "male-actor-1" }
  let(:collection1) { "collection-1" }
  let(:ctag1) { "ct1" }
  let(:title1) { "scene-title-1" }
  let(:date) { Time.parse("2013-12-08T00:00:00+00:00") }
  let(:key1) { scene1.key }
  let(:id1) { "9999" }
  let(:filename1) { "file_name-1.mp4" }
  let(:filename1_path) { File.expand_path(File.join("test_folder", filename1)) }
  let(:duplicate_filename1_path) { File.expand_path(File.join("test_folder", "nested_folder", filename1)) }
  let(:filename1_old) { "file_name-1_old.mp4" }
  let(:filename1_old_path) { File.expand_path(File.join("test_folder", filename1_old)) }

  # scene 2
  let(:scene2) do
    XxxRename::Data::SceneData.new(
      female_actors: [female_actor2],
      male_actors: [male_actor2],
      actors: [female_actor2, male_actor2],
      collection: collection2,
      collection_tag: ctag2,
      title: title2,
      id: id2,
      date_released: date
    )
  end
  let(:female_actor2) { "female-actor-2" }
  let(:male_actor2) { "male-actor-2" }
  let(:collection2) { "collection-2" }
  let(:ctag2) { "ct2" }
  let(:title2) { "scene-title-2" }
  let(:date) { Time.parse("2013-12-08T00:00:00+00:00") }
  let(:key2) { scene2.key }
  let(:id2) { "8888" }
  let(:filename2) { "file_name-2.mp4" }
  let(:filename2_path) { File.expand_path(File.join("test_folder", filename2)) }

  before(:each) do
    FileUtils.touch(File.join("test_folder", filename1))
    FileUtils.mkpath(File.join("test_folder", "nested_folder"))
    FileUtils.touch(File.join("test_folder", "nested_folder", filename1))
    FileUtils.touch(File.join("test_folder", filename1_old))
    FileUtils.touch(File.join("test_folder", filename2))
  end

  describe ".create" do
    context "new scene" do
      before { data_store.create!(scene1) }
      it "saves the scene successfully" do
        store.transaction(true) do
          expect(store[key1]).to eq(scene1)
          expect(store["#{ctag1}$#{id1}"]).to eq(key1)
          # expect(store[data_store.generate_lookup_key(ctag1, title1)]).to eq(key1)
          expect(store[data_store.generate_lookup_key(collection1, title1)]).to eq(key1)
          # expect(store[data_store.generate_lookup_key(title1, [female_actor1, male_actor1].join("|"))]).to eq(Set.new([key1]))
        end
      end
    end

    context "duplicate entry" do
      before { data_store.create!(scene1) }

      it "raises UniqueRecordViolation exception" do
        expect { data_store.create!(scene1) }.to raise_error(XxxRename::Data::UniqueRecordViolation)
      end
    end
  end

  describe ".count" do
    before { data_store.create!(scene1) }

    it "returns number of stored scenes" do
      expect(data_store.count).to eq 1
    end
  end

  describe ".empty?" do
    context "when datastore is empty" do
      it { expect(data_store.empty?).to eq(true) }
    end

    context "when datastore not empty" do
      before { data_store.create!(scene1) }

      it { expect(data_store.empty?).to eq(false) }
    end

    context "when datastore is emptied" do
      before do
        data_store.create!(scene1)
        data_store.destroy(scene1)
      end

      it { expect(data_store.empty?).to eq(true) }
    end
  end

  describe ".all" do
    before do
      data_store.create!(scene1)
      data_store.create!(scene2)
    end

    it "returns number of stored scenes" do
      expect(data_store.all).to match_array([scene1, scene2])
    end
  end

  describe ".metadata" do
    context "when metadata does not exist" do
      it { expect(data_store.metadata).to be_nil }
    end

    context "when metadata exists" do
      let(:metadata) { XxxRename::Data::SiteClientMetaData.create("some url") }

      before { data_store.update_metadata(metadata) }

      it { expect(data_store.metadata).to eq(metadata) }
    end
  end

  describe ".update_metadata" do
    context "when metadata type is incorrect" do
      it {
        # noinspection RubyMismatchedArgumentType
        expect { data_store.update_metadata({}) }
          .to raise_error(ArgumentError, "expected metadata of type XxxRename::Data::SiteClientMetaData, but received Hash")
      }
    end

    context "when metadata type is correct" do
      let(:metadata) { XxxRename::Data::SiteClientMetaData.create("some url") }

      before { data_store.update_metadata(metadata) }

      it "stores the metadata" do
        store.transaction(true) do
          actual_metadata = store[XxxRename::Data::METADATA_ROOT]
          expect(actual_metadata).to eq(metadata)
        end
      end

      context "when metadata is updated" do
        let(:updated_metadata) { metadata.mark_complete }

        before { data_store.update_metadata(updated_metadata) }

        it "stores the metadata" do
          store.transaction(true) do
            actual_metadata = store[XxxRename::Data::METADATA_ROOT]
            expect(actual_metadata).to eq(updated_metadata)
          end
        end
      end
    end
  end

  describe ".find" do
    before { data_store.create!(scene1) }

    context "scene exists" do
      it "search by collection_tag and id is success" do
        expect(data_store.find(collection_tag: ctag1, id: "9999")).to eq([scene1])
      end

      # it "search by collection_tag and title is success" do
      #   expect(data_store.find(collection_tag: ctag1, title: title1)).to eq([scene1])
      # end

      # it "search by title and actors is success", :aggregate_failures do
      #   expect(data_store.find(title: title1, actors: [female_actor1, male_actor1])).to eq([scene1])
      #   expect(data_store.find(title: title1, actors: [male_actor1, female_actor1])).to eq([scene1])
      # end
    end

    context "scene does not exist" do
      it "search by collection_tag and id returns an empty array" do
        expect(data_store.find(collection_tag: ctag2, id: "8888")).to eq([])
      end

      it "search by collection_tag and title returns an empty array" do
        expect(data_store.find(collection_tag: ctag2, title: title2)).to eq([])
      end

      it "search by title and actors returns an empty array", :aggregate_failures do
        expect(data_store.find(title: title2, actors: [female_actor2, male_actor2])).to eq([])
        expect(data_store.find(title: title2, actors: [male_actor2, female_actor2])).to eq([])
      end
    end

    it "raises an error when called with no params" do
      expect { data_store.find }.to raise_error(ArgumentError, "no key provided for lookup")
    end

    it "raises an error when actors is not an array" do
      expect { data_store.find(actors: "abc", title: title1) }.to raise_error(TypeError, "actors: wrong argument type String (expected Array)")
    end
  end

  describe "find_by_abs_path?" do
    before do
      data_store.create!(scene1)
      data_store.register_file(scene1, filename1_path)
    end

    it "returns the scene data if path is valid" do
      expect(data_store.find_by_abs_path?(filename1_path)).to eq(scene1)
    end

    it "returns nil if the path does not exist" do
      expect(data_store.find_by_abs_path?(filename2_path)).to be nil
    end
  end

  describe "find_by_base_filename?" do
    before do
      data_store.create!(scene1)
      data_store.register_file(scene1, filename1_path)
      data_store.register_file(scene1, duplicate_filename1_path)
    end

    it "returns the scene data if path is valid" do
      expect(data_store.find_by_base_filename?(filename1)).to eq([scene1, scene1])
    end

    it "returns nil if the path does not exist" do
      expect(data_store.find_by_base_filename?(filename2_path)).to be nil
    end
  end

  describe ".find_by_key?" do
    before { data_store.create!(scene1) }

    it "returns the scene data if key is valid" do
      expect(data_store.find_by_key?(key1)).to eq(scene1)
    end

    it "returns nil if key does not exist" do
      expect(data_store.find_by_key?(key2)).to be nil
    end
  end

  describe ".register_file" do
    before { data_store.create!(scene1) }

    context "scene exists with no filename" do
      before { data_store.register_file(scene1, filename1_path) }

      it "adds the absolute path of filename to the index" do
        store.transaction(true) do
          key = data_store.generate_lookup_key(XxxRename::Data::REGISTERED_FILE_PATHS_PREFIX, filename1_path)
          expect(store[key]).to eq(scene1.key)
        end
      end

      it "adds the base filename to the index" do
        store.transaction(true) do
          key = data_store.generate_lookup_key(XxxRename::Data::REGISTERED_FILE_BASENAME_PATH_PREFIX, File.basename(filename1_path))
          expect(store[key]).to eq([scene1.key])
        end
      end
    end

    context "scene exists with an old name" do
      context "when old filename exists" do
        before do
          data_store.register_file(scene1, filename1_old_path)
          data_store.register_file(scene1, filename1_path, old_filename: filename1_old_path)
        end

        it "adds the absolute path of file to the index and removes the old name" do
          store.transaction(true) do
            key = data_store.generate_lookup_key(XxxRename::Data::REGISTERED_FILE_PATHS_PREFIX, filename1_path)
            expect(store[key]).to eq(key1)
          end
        end

        it "adds the basename of file to the index and removes the old name" do
          store.transaction(true) do
            key = data_store.generate_lookup_key(XxxRename::Data::REGISTERED_FILE_BASENAME_PATH_PREFIX, File.basename(filename1_path))
            expect(store[key]).to eq([key1])
          end
        end
      end

      context "when the old file does not exist" do
        before do
          FileUtils.touch(File.join("test_folder", "xyz"))
          non_existent_file = File.expand_path(File.join("test_folder", "xyz"))

          data_store.register_file(scene1, filename1_path, old_filename: non_existent_file)
        end

        it "does not raise an error if old filename does not exist in data store" do
          store.transaction(true) do
            key = data_store.generate_lookup_key(XxxRename::Data::REGISTERED_FILE_PATHS_PREFIX, filename1_path)
            expect(store[key]).to eq(key1)
          end
        end
      end
    end
  end

  describe ".exists?" do
    before { data_store.create!(scene1) }

    it "returns true if scene exists in datastore" do
      expect(data_store.exists?(key1)).to be true
    end

    it "returns false if scene does not exists in datastore" do
      expect(data_store.exists?(key2)).to be false
    end
  end

  describe ".destroy" do
    before do
      data_store.create!(scene1)
      data_store.create!(scene2)
    end

    context "when a saved scene is destroyed" do
      before { data_store.destroy(scene1, filename1_path, filename1_old) }

      it "removes only the correct scene from the datastore" do
        store.transaction(true) do
          expect(store[key1]).to be_nil
          expect(store[key2]).to eq(scene2)
        end
      end

      it "cleans up indexes" do
        store.transaction(true) do
          expect(store["#{ctag1}$#{id1}"]).to eq(nil)
          # expect(store[data_store.generate_lookup_key(ctag1, title1)]).to eq(nil)
          expect(store[data_store.generate_lookup_key(collection1, title1)]).to eq(nil)
          # expect(store[data_store.generate_lookup_key(title1, [female_actor1, male_actor1].join("|"))]).to eq(nil)

          expect(store["#{ctag2}$#{id2}"]).to eq(key2)
          # expect(store[data_store.generate_lookup_key(ctag2, title2)]).to eq(key2)
          expect(store[data_store.generate_lookup_key(collection2, title2)]).to eq(key2)
          # expect(store[data_store.generate_lookup_key(title2, [female_actor2, male_actor2].join("|"))]).to eq(Set.new([key2]))
        end
      end
    end

    context "scene title , actors index has more than one scene" do
      let(:index_key) { data_store.generate_lookup_key(title1, [female_actor1, male_actor1].join("|")) }
      before do
        store.transaction do
          store[index_key] ||= Set.new
          store[index_key].add("abc")
        end
      end

      it "only removes the key of the destroyed scene" do
        data_store.destroy(scene1, filename1_path, filename1_old)
        store.transaction(true) do
          expect(store[index_key]).to eq(Set.new(["abc"]))
        end
      end
    end
  end

  describe ".valid?" do
    before do
      data_store.create!(scene1)
      data_store.register_file(scene1, filename1_path)
    end

    it "returns true" do
      expect(data_store.valid?(scene1, filepath: filename1_path)).to be true
    end

    context "with invalid scene" do
      let(:errors) { data_store.valid?(scene1, filepath: filename1_path) }

      context "missing scene id" do
        before { store.transaction { store.delete(key1) } }

        it "returns missing keys" do
          expect(errors.scene_saved).to be false
        end
      end

      context "missing id index" do
        before { store.transaction { store.delete(data_store.generate_lookup_key(ctag1, id1)) } }

        it "returns missing keys" do
          expect(errors.missing_keys).to eq([:id_index])
        end
      end

      context "conflicting id index" do
        before { store.transaction { store[data_store.generate_lookup_key(ctag1, id1)] = "abc" } }

        it "returns conflicting keys" do
          expect(errors.conflicting_indexes).to eq({ id_index: "abc" })
        end
      end

      # context "missing title index" do
      #   before { store.transaction { store.delete(data_store.generate_lookup_key(ctag1, title1)) } }
      #
      #   it "returns missing keys" do
      #     expect(errors.missing_keys).to eq([:title_index])
      #   end
      # end

      # context "conflicting title index" do
      #   before { store.transaction { store[data_store.generate_lookup_key(ctag1, title1)] = "abc" } }
      #
      #   it "returns conflicting keys" do
      #     expect(errors.conflicting_indexes).to eq({ title_index: "abc" })
      #   end
      # end

      context "missing collection/title index" do
        before { store.transaction { store.delete(data_store.generate_lookup_key(collection1, title1)) } }

        it "returns missing keys" do
          expect(errors.missing_keys).to eq([:collection_title_index])
        end
      end

      context "conflicting collection/title index" do
        before { store.transaction { store[data_store.generate_lookup_key(collection1, title1)] = "abc" } }

        it "returns conflicting keys" do
          expect(errors.conflicting_indexes).to eq({ collection_title_index: "abc" })
        end
      end

      # context "missing title/actors index" do
      #   let(:index_key) { data_store.generate_lookup_key(title1, scene1.actors.sort.join("|")) }
      #
      #   before { store.transaction { store.delete(index_key) } }
      #
      #   it "returns missing keys" do
      #     expect(errors.missing_keys).to eq([:title_actors_index])
      #   end
      # end

      # context "conflicting title/actors index" do
      #   let(:index_key) { data_store.generate_lookup_key(title1, scene1.actors.sort.join("|")) }
      #
      #   before { store.transaction { store[index_key] = Set.new(["abc"]) } }
      #
      #   it "returns conflicting keys" do
      #     expect(errors.conflicting_indexes).to eq(title_actors_index: Set.new(["abc"]))
      #   end
      # end

      context "missing file path" do
        let(:index_key) { data_store.generate_lookup_key(XxxRename::Data::REGISTERED_FILE_PATHS_PREFIX, filename1_path) }

        before { store.transaction { store.delete(index_key) } }

        it "returns missing keys" do
          expect(errors.missing_keys).to eq([:path])
          expect(errors.expected_filename_key).to match(/filename1mp4/)
        end
      end
    end
  end
end
