# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/arch_angel_video"
require "xxx_rename/data/scene_data"

RSpec.describe XxxRename::SiteClients::ArchAngelVideo do
  WebMock.disable_net_connect!(allow: /tour.archangelworld.com/)

  subject(:site_client) { described_class.new(config) }

  include_context "config provider"

  shared_context "hardcoded scene details" do
    let(:movie) { "https://tour.archangelworld.com/dvds/beautiful-tits-vol-2.html" }
    let(:movie_hash) do
      {
        name: "Beautiful Tits Vol. 2",
        front_image: "https://tour.archangelworld.com/content//contentthumbs/00/15/15-dvd-3x.jpg",
        studio: "ArchAngel Video",
        url: movie
      }
    end
    let(:expected_scene_data) do
      XxxRename::Data::SceneData.new(
        {
          female_actors: ["Brooklyn Chase"],
          male_actors: [],
          actors: ["Brooklyn Chase"],
          collection: "Arch Angel",
          collection_tag: "AA",
          title: "Brooklyn Chase Hot Bigtits Babe Fucked",
          date_released: Time.parse("2015-10-05 23:00:00 UTC"),
          description: "Brooklyn Chase showing off her massive mounds in a bikini outdoors and in before " \
                         "having them sucked on and her pussy eaten. Brooklyn sucks cock then goes for a hardcore " \
                         "ride and is banged good with her huge boobs bouncing all over. Dude titty fucks those " \
                         "beautiful tits, fucks her more then unloads giving her a messy chest of cum.",
          scene_link: "https://tour.archangelworld.com/trailers/Brooklyn-Chase-Hot-Bigtits-Babe-Fucked.html",
          scene_cover: "https://tour.archangelworld.com/content//contentthumbs/24/49/2449-3x.jpg",
          movie: movie_hash
        }
      )
    end
  end

  describe ".refresh_datastore" do
    context "when processing the first API response" do
      before do
        allow(config.actor_helper).to receive(:auto_fetch!).and_return(nil)
        expect(site_client).to(receive(:movie_links).with(1).and_wrap_original { |m, *args| [m.call(*args).first] })
        expect(site_client).to(receive(:movie_links).with(2).and_wrap_original { |_m, *_args| [] })

        site_client.refresh_datastore(1)
      end

      it "should add some scenes to the datastore" do
        expect(site_client.site_client_datastore.count).to be > 0
      end
    end

    context "when the movie link is hardcoded" do
      include_context "hardcoded scene details"

      let(:movie_result) { described_class::MovieResult.new(movie, XxxRename::Data::SceneMovieData.new(movie_hash)) }

      before do
        # Stub Actor Helper
        allow(config.actor_helper).to receive(:auto_fetch!).and_return(nil)
        config.actors_datastore.create!("Brooklyn Chase", "female")

        # Force the movie_links method to only return the hardcoded URL
        expect(site_client).to(receive(:movie_links).with(1).and_wrap_original { |_m, *_args| [movie_result] })
        expect(site_client).to(receive(:movie_links).with(2).and_wrap_original { |_m, *_args| [] })

        # Force the process_scenes to return the first scene from the movie
        expect(site_client).to(receive(:process_scenes).with(movie_result).and_wrap_original { |m, *args| [m.call(*args).first] })

        # Invoke the test method
        site_client.refresh_datastore(1)
      end

      it "adds the scenes to the datastore" do
        expect(site_client.site_client_datastore.count).to be > 0
      end

      it "adds the correct scene details" do
        expect(site_client.site_client_datastore.all&.first).to eq_scene_data(expected_scene_data)
      end
    end
  end

  describe ".datastore_refresh_required?" do
    context "when the override flag is true" do
      let(:override_config) { { "force_refresh_datastore" => true } }

      it { expect(site_client.datastore_refresh_required?).to eq(true) }

      context "when all the scenes have been processed" do
        before { site_client.instance_variable_set(:@all_scenes_processed, true) }

        it { expect(site_client.datastore_refresh_required?).to eq(false) }
      end
    end

    context "when override flag is false" do
      context "when all the scenes have been processed" do
        before { site_client.instance_variable_set(:@all_scenes_processed, true) }

        it { expect(site_client.datastore_refresh_required?).to eq(false) }
      end

      context "when site client datastore is empty" do
        it { expect(site_client.datastore_refresh_required?).to eq(true) }
      end
    end
  end

  describe ".search" do
    include_context "hardcoded scene details"
    let(:file) { "Brooklyn Chase Hot Bigtits Babe Fucked [C] ArchAngel [A] Brooklyn Chase.mp4" }
    let(:pattern) { "%title [C] %collection [A] %actors" }

    let(:override_config) do
      { "site" => { "arch_angel" => { "file_source_format" => [pattern] } } }
    end

    context "when datastore has the matching scene" do
      before do
        allow(site_client).to receive(:datastore_refresh_required?).and_return(false)
        # noinspection RubyMismatchedArgumentType
        site_client.site_client_datastore.create!(expected_scene_data, force: true)
      end

      it "returns the correct scene data" do
        expect(site_client.search(file)).to eq(expected_scene_data)
      end
    end

    context "when datastore has no matching scenes" do
      before do
        allow(site_client).to receive(:datastore_refresh_required?).and_return(false)
      end

      it "raises an error" do
        expect { site_client.search(file) }.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
      end
    end
  end
end
