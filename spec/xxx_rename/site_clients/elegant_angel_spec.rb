# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/elegant_angel"

describe XxxRename::SiteClients::ElegantAngel do
  before { WebMock.disable_net_connect!(allow: /elegantangel.com/) }

  subject(:site_client) { described_class.new(config) }

  describe ".datastore_refresh_required?" do
    include_context "config provider" do
      let(:override_config) do
        { "force_refresh_datastore" => force_refresh_datastore }
      end
    end

    context "when force override is true" do
      let(:force_refresh_datastore) { true }
      it { expect(site_client.datastore_refresh_required?).to eq(true) }
    end

    context "when force override is false" do
      let(:force_refresh_datastore) { false }

      context "when site datastore is empty" do
        it { expect(site_client.datastore_refresh_required?).to eq(true) }
      end

      context "when site client has all the latest scenes" do
        before do
          allow(config.actor_helper).to receive(:auto_fetch!).and_return(nil)
          expect(site_client).to(receive(:movie_links).with(1).twice.and_wrap_original { |m, *args| [m.call(*args).first] })
          expect(site_client).to(receive(:movie_links).with(2).and_wrap_original { |_m, *_args| [] })

          site_client.refresh_datastore(1)
        end

        it { expect(site_client.datastore_refresh_required?).to eq(false) }
      end
    end
  end

  describe ".refresh_datastore" do
    include_context "config provider"

    context "when all the scenes are processed" do
      before do
        allow(config.actor_helper).to receive(:auto_fetch!).and_return(nil)
        expect(site_client).to(receive(:movie_links).with(1).and_wrap_original { |m, *args| [m.call(*args).first] })
      end

      before do
        expect(site_client).to(receive(:movie_links).with(2).and_wrap_original { |_m, *_args| [] })

        site_client.refresh_datastore(1)
      end

      it "updates the metadata as complete" do
        expect(site_client.metadata.complete?).to eq(true)
      end
    end

    context "when the scraping fails due to some error" do
      # TODO: This needs to be implemented
      # before do
      #   expect(site_client).to(receive(:movie_links).with(2).and_raise(RuntimeError, "some error"))
      # end
      #
      # it "raises an error and updates the metadata" do
      #   expect { site_client.refresh_datastore(2) }.to raise_error(RuntimeError)
      #
      #   expect(site_client.metadata.failure?).to eq(true)
      #   expect(site_client.metadata.failure.checkpoint).not_to eq(nil)
      # end
    end
  end

  describe ".search" do
    context "force datastore refresh" do
      include_context "config provider" do
        let(:override_config) do
          { "force_refresh_datastore" => force_refresh_datastore,
            "site" => {
              "elegant_angel" => {
                "file_source_format" => [
                  "%collection [T] %title"
                ]
              }
            } }
        end
      end

      before do
        allow(config.actor_helper).to receive(:auto_fetch!).and_return(nil)
        config.actors_datastore.create!("Chastity Lynn", "female")
        config.actors_datastore.create!("Ana Foxxx", "female")
        config.actors_datastore.create!("Charley Chase", "female")
        config.actors_datastore.create!("Tori Black", "female")
        config.actors_datastore.create!("Alexis Texas", "female")
      end

      let(:store) { config.scene_datastore.store }
      let(:force_refresh_datastore) { true }

      let(:file1) { "oiled up 2 [T] scene 2.mp4" }
      let(:url1) { "https://www.elegantangel.com/1603549/oiled-up-2-streaming-porn-videos.html" }
      let(:scene_data1) do
        XxxRename::Data::SceneData.new(
          {
            male_actors: [],
            actors: ["Chastity Lynn", "Ana Foxxx"],
            female_actors: ["Chastity Lynn", "Ana Foxxx"],
            collection: "Oiled Up 2",
            collection_tag: "EL",
            title: "Scene 2",
            date_released: Time.parse("2012-01-26"),
            scene_link: "https://www.elegantangel.com/159802/elegant-angel-scene-2-streaming-scene-video.html",
            scene_cover: "https://caps1cdn.adultempire.com/r/9948/320/1599948_03880_320.jpg",
            movie: { name: "Oiled Up 2",
                     date: Time.parse("2012-01-26"),
                     url: "https://www.elegantangel.com/1603549/oiled-up-2-streaming-porn-videos.html",
                     front_image: "https://imgs1cdn.adultempire.com/product/500/1599948/oiled-up-2.jpg",
                     back_image: "https://imgs1cdn.adultempire.com/product/500/1599948b/oiled-up-2.jpg",
                     studio: "Elegant Angel",
                     synopsis: "These hardbodies starlets are drenched and glistening in oil! Featuring the " \
                               "amazing Jayden Jaymes, as well as Juelz Ventura, Nikki Fairchild, Chasity Lynn, " \
                               "Anna Foxxx, Shazia Sahari and Victoria Love! Directed by L.T.Do not miss!" }
          }
        )
      end

      let(:scene_data2) do
        XxxRename::Data::SceneData.new(
          {
            male_actors: [],
            female_actors: ["Charley Chase", "Tori Black", "Alexis Texas"],
            actors: ["Charley Chase", "Tori Black", "Alexis Texas"],
            collection: "Tori Black Is Pretty Filthy 2",
            collection_tag: "EL",
            title: "Three hot girls rock the boat",
            date_released: Time.parse("2010-09-30"),
            scene_link: "https://www.elegantangel.com/144628/elegant-angel-three-hot-girls-rock-the-boat-streaming-scene-video.html",
            scene_cover: "https://caps1cdn.adultempire.com/q/7340/720/1547340_05060_720c.jpg",
            movie: { name: "Tori Black Is Pretty Filthy 2",
                     date: Time.parse("2010-09-30"),
                     url: "https://www.elegantangel.com/1552100/tori-black-is-pretty-filthy-2-streaming-porn-videos.html",
                     front_image: "https://imgs1cdn.adultempire.com/product/500/1547340/tori-black-is-pretty-filthy-2.jpg",
                     back_image: "https://imgs1cdn.adultempire.com/product/500/1547340b/tori-black-is-pretty-filthy-2.jpg",
                     studio: "Elegant Angel",
                     synopsis: "Tori Black Is Pretty Filthy was one of the biggest movies of 2009, winning awards at AVN, XRCO, " \
             "and Xbiz award ceremonies. The performer of the year returns in the sequel to her own movie, featuring " \
             "her very 1st DP scene (on or off camera) as well as anal and interracial scenes.. Do not miss this " \
             "intimate insight into the beauty and sexuality of the star who was recently voted \"The Sexiest Pornstar " \
             "Ever\" by Elegant Angel readers.Tori Black's first Double Penetration!!!" }
          }
        )
      end

      let(:file2) { "tori black is pretty filthy 2 [T] three hot girls rock the boat.mp4" }
      let(:url2) { "https://www.elegantangel.com/1552100/tori-black-is-pretty-filthy-2-streaming-porn-videos.html" }

      describe ".refresh_datastore" do
        let(:file) { file1 }

        context "when there are no results on page 3" do
          before do
            expect(site_client).to(receive(:movie_links).with(1).and_wrap_original { |m, *args| [m.call(*args).first] })
            expect(site_client).to(receive(:movie_links).with(2).and_wrap_original { |_m, *_args| [] })
          end

          it "processes exactly one movies", :aggregate_failures do
            expect { site_client.search(file) }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
            processed_movies = site_client.site_client_datastore.all&.map { |x| x.movie.name }&.uniq&.length
            expect(processed_movies).to eq(1)
            expect(site_client.all_scenes_processed?).to be true
            expect(site_client.oldest_processable_date?).to be false
          end
        end

        context "when the first movie's release year is less than OLDEST_PROCESSABLE_MOVIE_YEAR" do
          before do
            # oldest movie on website
            old_movie = "https://www.elegantangel.com/2970037/everything-is-not-relative-streaming-porn-videos.html"
            expect(site_client).to(receive(:movie_links).with(1).and_wrap_original { |_m, *_args| [old_movie] })
          end

          it "processes no movies", :aggregate_failures do
            expect { site_client.search(file) }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
            expect(site_client.site_client_datastore.count).to eq(0)
            expect(site_client.all_scenes_processed?).to be false
            expect(site_client.oldest_processable_date?).to be true
          end
        end
      end

      describe "file match" do
        context "pattern 1" do
          let(:file) { file1 }
          let(:scene_data) { scene_data1 }

          before do
            expect(site_client).to(receive(:movie_links).with(1).and_wrap_original { |_m, *_args| [url1] })
            expect(site_client).to(receive(:movie_links).with(2).and_wrap_original { |_m, *_args| [] })
          end

          it "returns a successful match" do
            expect(site_client.search(file)).to eq_scene_data(scene_data)
          end
        end

        context "pattern 2" do
          let(:file) { file2 }
          let(:scene_data) { scene_data2 }

          before do
            expect(site_client).to(receive(:movie_links).with(1).and_wrap_original { |_m, *_args| [url2] })
            expect(site_client).to(receive(:movie_links).with(2).and_wrap_original { |_m, *_args| [] })
          end

          it "returns a successful match" do
            expect(site_client.search(file)).to eq_scene_data(scene_data)
          end
        end
      end
    end
  end
end
