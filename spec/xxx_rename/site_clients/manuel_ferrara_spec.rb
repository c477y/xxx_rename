# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/manuel_ferrara"

describe XxxRename::SiteClients::ManuelFerrara do
  before { WebMock.disable_net_connect!(allow: /(manuelferrara|julesjordan).com/) }

  subject(:site_client) { described_class.new(config) }
  before { allow_any_instance_of(XxxRename::ActorsHelper).to receive(:auto_fetch!).and_return(nil) }

  describe ".search" do
    include_context "config provider" do
      let(:override_config) do
        { "force_refresh_datastore" => force_refresh_datastore,
          "site" => {
            "manuel_ferrara" => {
              "file_source_format" => [
                "%title [C] %collection [A] %actors"
              ]
            }
          } }
      end
    end

    let(:filename) { "Kayley Gunner Is Super Stacked [C] Manuel Ferrara [A] Kayley Gunner, Manuel Ferrara.mp4" }
    let(:scene_data) do
      XxxRename::Data::SceneData.new(
        { female_actors: [],
          male_actors: [],
          actors: [],
          collection: "Manuel Ferrara",
          collection_tag: "MNF",
          title: "Kayley Gunner Is Super Stacked",
          id: nil,
          date_released: Time.parse("2022-08-24") }
      )
    end

    context "when force_refresh_datastore is false" do
      let(:force_refresh_datastore) { false }

      it "raises no match error" do
        expect(site_client).not_to receive(:refresh_datastore)
        expect { site_client.search(filename) }
          .to raise_error(
            an_instance_of(XxxRename::SiteClients::Errors::NoMatchError)
              .and(having_attributes(code: XxxRename::SiteClients::Errors::NoMatchError::ERR_NO_RESULT))
          )
      end
    end

    context "with un-hardcoded #get_scenes_from_page" do
      let(:force_refresh_datastore) { true }

      before do
        expect(site_client).to(receive(:get_scenes_from_page).with(1).and_wrap_original { |m, *args| [m.call(*args).first] })
        expect(site_client).to(receive(:all_scenes_urls).and_wrap_original { |m, *args| [m.call(*args).first] })
        expect(site_client).to(receive(:get_scenes_from_page).with(2).and_wrap_original { |_m, *_args| [] })
      end

      it "should have processed a scene", :aggregate_failures do
        expect { site_client.search(filename) }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
        expect(site_client.site_client_datastore.all.length).to be > 0
        expect(site_client.all_scenes_processed?).to be true
      end
    end

    context "with hardcoded #get_scenes_from_page" do
      let(:force_refresh_datastore) { true }

      let(:url) { "https://manuelferrara.com/trial/scenes/Kayley-Gunner-Facial_vids.html" }

      before do
        expect(site_client).to(receive(:all_scenes_urls).and_wrap_original { |_m, *_args| [url] })
        expect(site_client).to(receive(:all_scenes_urls).and_wrap_original { |_m, *_args| [] })
      end

      it "returns the expected response", :aggregate_failures do
        expect(site_client.search(filename)).to eq(scene_data)
        expect(site_client.site_client_datastore.all.length).to eq(1)
        expect(site_client.all_scenes_processed?).to be true
      end
    end

    context "when called multiple times" do
      let(:force_refresh_datastore) { true }

      it "does not call get_scenes_from_page twice" do
        expect(site_client).to receive(:get_scenes_from_page).exactly(1).time.and_return([])
        # search once
        expect { site_client.search(filename) }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
        # search again
        expect { site_client.search(filename) }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
      end
    end
  end
end
