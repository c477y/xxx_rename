# frozen_string_literal: true

require "rspec"

describe XxxRename::Client do
  include_context "config provider" do
    let(:override_config) { { "actions" => actions } }
  end

  describe ".generate" do
    subject(:client) { described_class.new(config, verbose: false, nested: false) }

    let(:file) { "StunningCurves_s02_GracieGlam_ChrisStrokes_540p.mp4" }
    let(:actions) { [] }

    context "successful generate" do
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          female_actors: ["Gracie Glam", "Keisha Grey"],
          male_actors: ["Chris Strokes"],
          actors: ["Gracie Glam", "Keisha Grey", "Chris Strokes"],
          collection: "Stunning Curves",
          collection_tag: "EA",
          title: "Stunning Curves, Scene #02",
          id: "73343",
          date_released: Time.parse("2015-04-14 00:00:00 +0100")
        )
      end

      before(:each) { FileUtils.touch(File.join("test_folder", file)) }
      let(:object) { File.join("test_folder", file) }

      before { client.matcher.initialise_site_client(:evil_angel) }

      context "successful match" do
        before do
          expect(client.matcher.fetch(:evil_angel)).to receive(:search).with(file).and_return(scene_data)
        end

        let(:expected_search_results) do
          XxxRename::Search::SearchResult.new(scene_data: scene_data, site_client: client.matcher.fetch(:evil_angel))
        end

        context "with no actions" do
          it "yields with expected parameters" do
            expect { |b| client.generate(object, &b) }.to yield_with_args(/test_folder/, file, expected_search_results)
          end
        end
      end

      context "no match" do
        before do
          expect(client.matcher.fetch(:evil_angel)).to receive(:search).with(file).and_return(nil)
        end

        it "does not yield" do
          expect { |b| client.generate(object, &b) }.not_to yield_with_args(/test_folder/, file, XxxRename::Search::SearchResult)
        end
      end
    end

    context "with invalid object" do
      let(:object) { file }

      it "raises error" do
        expect { client.generate(object) }.to raise_error(XxxRename::Errors::FatalError, /UNKNOWN OBJECT/)
      end
    end
  end
end
