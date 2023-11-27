# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::ManuelFerrara do
  subject(:site_client) { described_class.new }

  include_context "actor-helper stubber"
  include_context "config provider"

  describe ".search" do
    let(:search) { site_client.search(filename, parsed_scene_data: parsed_scene_data) }
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

    let(:filename) { "Kayley Gunner Is Super Stacked [C] Manuel Ferrara [A] Kayley Gunner, Manuel Ferrara.mp4" }

    let(:parsed_scene_data) do
      XxxRename::Data::ParsedSceneData.new(
        actors: ["Kayley Gunner", "Manuel Ferrara"],
        collection: "Manuel Ferrara",
        title: "Kayley Gunner Is Super Stacked"
      )
    end

    context "when force_refresh_datastore is false" do
      let(:force_refresh_datastore) { false }

      it "raises no match error" do
        expect(site_client).not_to receive(:refresh_datastore)
        expect { search }
          .to raise_error(
            an_instance_of(XxxRename::SiteClients::Errors::NoMatchError)
              .and(having_attributes(code: XxxRename::SiteClients::Errors::NoMatchError::ERR_NO_RESULT))
          )
      end
    end

    context "with un-hardcoded #get_scenes_from_page" do
      let(:force_refresh_datastore) { true }
      before { disable_actor_fetch(config) }

      before do
        expect(site_client).to(receive(:get_scenes_from_page).with(1).and_wrap_original { |m, *args| [m.call(*args).first] })
        expect(site_client).to(receive(:all_scenes_urls).and_wrap_original { |m, *args| [m.call(*args).first] })
        expect(site_client).to(receive(:get_scenes_from_page).with(2).and_wrap_original { |_m, *_args| [] })
      end

      it "should have processed a scene", :aggregate_failures do
        expect do
          VCR.use_cassette("manuel_ferrara_client/non_hardcoded_test#success") do
            @result = search
          end
        end.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)

        expect(site_client.site_client_datastore.all.length).to be > 0
        expect(site_client.all_scenes_processed?).to be true
      end
    end

    context "with hardcoded #get_scenes_from_page" do
      let(:force_refresh_datastore) { true }
      let(:url) { "https://manuelferrara.com/trial/scenes/Kayley-Gunner-Facial_vids.html" }
      let(:scene_data) do
        XxxRename::Data::SceneData.new(
          { female_actors: ["Kayley Gunner"],
            male_actors: ["Manuel Ferrara"],
            actors: ["Kayley Gunner", "Manuel Ferrara"],
            collection: "Manuel Ferrara",
            collection_tag: "MNF",
            title: "Kayley Gunner Is Super Stacked",
            date_released: Time.parse("2022-08-24"),
            director: "Jules Jordan",
            scene_link: "https://manuelferrara.com/trial/scenes/Kayley-Gunner-Facial_vids.html",
            scene_cover: "https://thumbs.julesjordan.com/trial/content//contentthumbs/218621.jpg",
            description: "Super Stacked nympho, Kayley Gunner yells out \"my pussy needs to be fucked so bad\"!",
            movie: {
              name: "Super Stacked #2",
              url: "https://manuelferrara.com/trial/dvds/super-stacked-2.html",
              front_image: "https://thumbs.julesjordan.com/trial/content//contentthumbs/56/91/5691-dvd-3x.jpg",
              back_image: "https://thumbs.julesjordan.com/trial/content//contentthumbs/57/01/5701-dvd-3x.jpg",
              studio: "Manuel Ferrara"
            } }
        )
      end

      before do
        stub_actor(config, "Manuel Ferrara", "male")
        stub_actor(config, "Kayley Gunner", "female")
        expect(site_client).to(receive(:all_scenes_urls).and_wrap_original { |_m, *_args| [url] })
        expect(site_client).to(receive(:all_scenes_urls).and_wrap_original { |_m, *_args| [] })
        VCR.use_cassette("manuel_ferrara_client/hardcoded#kayley_gunner_facial_vids#success") do
          @result = search
        end
      end

      it "returns the expected response", :aggregate_failures do
        expect(@result).to eq(scene_data)
        expect(site_client.site_client_datastore.all.length).to eq(1)
        expect(site_client.all_scenes_processed?).to be true
      end
    end

    context "when called multiple times" do
      let(:force_refresh_datastore) { true }

      it "does not call get_scenes_from_page twice" do
        expect(site_client).to receive(:get_scenes_from_page).exactly(1).time.and_return([])
        # search once
        expect { search }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
        # search again
        expect { search }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
      end
    end
  end
end
