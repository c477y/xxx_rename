# frozen_string_literal: true

require "rspec"
require "xxx_rename/filename_generator"

describe XxxRename::FilenameGenerator do
  let(:ext_name) { ".mp4" }

  describe ".generate" do
    subject(:call) { described_class.generate(scene_data, output_format, ext_name, prefix_hash) }

    let(:prefix_hash) do
      {
        female_actors_prefix: "[F]",
        male_actors_prefix: "[M]",
        actors_prefix: "[A]",
        title_prefix: "[T]",
        id_prefix: "[ID]"
      }
    end

    context "given scene data with all values present" do
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          female_actors: ["Devon"],
          male_actors: ["James Deen"],
          actors: ["Devon", "James Deen"],
          collection: "Doctor Adventures",
          collection_tag: "BZ",
          title: "Anal Is The Best Medicine",
          id: 1,
          date_released: Time.parse("2013-12-08")
        )
      end
      let(:output_format) do
        "%female_actors_prefix %female_actors %male_actors_prefix %male_actors %actors_prefix %actors - " \
        "%collection - %collection_tag %title_prefix %title %id_prefix %id - %yyyy_mm_dd - %dd - %mm - %yyyy"
      end
      let(:expected_filename) do
        "[F] Devon [M] James Deen [A] Devon, James Deen - Doctor Adventures - [BZ] [T] " \
        "Anal Is The Best Medicine [ID] 1 - 2013_12_08 - 08 - 12 - 2013.mp4"
      end

      it "using all tokens should return the correct response" do
        expect(call).to eq(expected_filename)
      end
    end

    context "given scene data with no male actors" do
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          female_actors: ["Devon"],
          male_actors: [],
          actors: ["Devon"],
          collection: "Doctor Adventures",
          collection_tag: "BZ",
          title: "Anal Is The Best Medicine",
          id: 1,
          date_released: Time.parse("2013-12-08")
        )
      end
      let(:output_format) do
        "%female_actors_prefix %female_actors %male_actors_prefix %male_actors %actors_prefix %actors - " \
        "%collection - %collection_tag %title_prefix %title %id_prefix %id - %yyyy_mm_dd - %dd - %mm - %yyyy"
      end

      it "should raise an error with missing id" do
        expect { call }.to raise_error(XxxRename::FilenameGenerationError,
                                       "Format contains token(s) %male_actors, but site client returned no values for these arguments.")
      end
    end

    context "given scene data with no id" do
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          female_actors: [],
          male_actors: [],
          actors: [],
          collection: "",
          title: "Anal Is The Best Medicine"
        )
      end
      let(:output_format) { "%title - %id" }

      it "should raise an error with missing id" do
        expect do
          call
        end.to raise_error(XxxRename::FilenameGenerationError,
                           "Format contains token(s) %id, but site client returned no values for these arguments.")
      end
    end

    context "given scene data with no timestamp" do
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          female_actors: [],
          male_actors: [],
          actors: [],
          collection: "",
          title: "Anal Is The Best Medicine"
        )
      end
      context "using token %yyyy_mm_dd" do
        let(:output_format) { "%title - %yyyy_mm_dd" }

        it "raise an error with missing date" do
          expect { call }
            .to raise_error(XxxRename::FilenameGenerationError,
                            "Format contains token(s) %yyyy_mm_dd, but site client returned no values for these arguments.")
        end
      end

      context "using token %yyyy, %mm and %dd" do
        let(:output_format) { "%title - %yyyy - %mm - %dd" }

        it "raise an error with missing date" do
          expect { call }
            .to raise_error(XxxRename::FilenameGenerationError,
                            "Format contains token(s) %yyyy, %mm, %dd, but site client returned no values for these arguments.")
        end
      end
    end

    context "given incorrect format" do
      let(:scene_data) { instance_double(XxxRename::Data::SceneData) }
      let(:output_format) { "%invalid - %yyyy_mm_dd" }

      it "raise an error" do
        expect { call }
          .to raise_error(XxxRename::InvalidFormatError, "invalid token(s) %invalid")
      end
    end
  end

  describe ".generate_with_multi_formats!" do
    subject(:generate) { described_class.generate_with_multi_formats!(scene_data, ext_name, prefix_hash, *formats) }

    let(:prefix_hash) do
      {
        female_actors_prefix: "-F-",
        male_actors_prefix: "-M-",
        actors_prefix: "-A-",
        title_prefix: "-T-",
        id_prefix: "--"
      }
    end

    context "when scene_data has no id" do
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          female_actors: ["Devon"],
          male_actors: ["James Deen"],
          actors: ["Devon", "James Deen"],
          collection: "Doctor Adventures",
          collection_tag: "BZ",
          title: "Anal Is The Best Medicine",
          id: nil,
          date_released: Time.parse("2013-12-08")
        )
      end

      context "and all formats require an id" do
        let(:formats) do
          [
            "%female_actors %female_actors_prefix %male_actors %male_actors_prefix %id",
            "%id_prefix %id %female_actors %female_actors_prefix"
          ]
        end

        it "raises an error" do
          er_msg = "Format contains token(s) %id, but site client returned no values for these arguments."
          expect { generate }.to raise_error(XxxRename::FilenameGenerationError, er_msg)
        end
      end

      context "first format generates a filename" do
        let(:formats) do
          [
            "%female_actors %female_actors_prefix %male_actors %male_actors_prefix",
            "%id_prefix %id %female_actors %female_actors_prefix"
          ]
        end

        it "returns a filename" do
          expect(generate).to eq("Devon -F- James Deen -M-.mp4")
        end
      end
    end
  end
end
