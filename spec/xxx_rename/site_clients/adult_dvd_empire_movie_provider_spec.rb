# frozen_string_literal: true

require "rspec"

RSpec.describe XxxRename::SiteClients::AdultDvdEmpireMovieProvider do
  subject { described_class.new(movie_name: movie_name, studio: studio) }

  describe ".fetch" do
    context "when movie match is unsuccessful" do
      let(:movie_name) { "Lorem Ipsum" }
      let(:studio) { "NO" }

      before do
        VCR.use_cassette("adult_dvd_empire/lorem_ipsum") do
          @result = subject.fetch
        end
      end

      it "returns nil" do
        expect(@result).to eq(nil)
      end
    end

    context "when movie match is successful: scenario 1" do
      let(:movie_name) { "Beautiful Tits Vol. 8" }
      let(:studio) { "ArchAngel" }
      let(:expected_response) do
        { name: "Beautiful Tits Vol. 8",
          date: Time.strptime("2021", "%Y").utc,
          url: "https://www.adultdvdempire.com/3150484/beautiful-tits-vol-8-porn-movies.html",
          front_image: "https://imgs1cdn.adultempire.com/products/84/3150484h.jpg",
          back_image: "https://imgs1cdn.adultempire.com/products/84/3150484bh.jpg",
          studio: "ArchAngel" }
      end

      before do
        VCR.use_cassette("adult_dvd_empire/beautiful_tits_vol_8") do
          @result = subject.fetch
        end
      end

      it { expect(@result.to_hash).to eq(expected_response.to_hash) }
    end

    context "when movie match is successful: scenario 2" do
      let(:movie_name) { "Beautiful Tits Vol. 4" }
      let(:studio) { "ArchAngel" }
      let(:expected_response) do
        { name: "Beautiful Tits Vol. 4",
          date: Time.strptime("2017", "%Y").utc,
          url: "https://www.adultdvdempire.com/1906824/beautiful-tits-vol-4-porn-movies.html",
          front_image: "https://imgs1cdn.adultempire.com/products/24/1906824h.jpg",
          back_image: "https://imgs1cdn.adultempire.com/products/24/1906824bh.jpg",
          studio: "ArchAngel",
          synopsis: "Angela White leads the pack in this stunning celebration of SICK FUCKIN TITTIES! " \
                    "There is nothing like more than a mouthful of mams cushioning a throbbing cock before " \
                    "watching them bounce in doggy, cowgirl and missionary positions! Angela gets her tight " \
                    "little ass stretched and filled before Roman covers her in goo! But what truly makes them " \
                    "Beautiful Tits is the creamy coating they get at the end of each scene!" }
      end

      before do
        VCR.use_cassette("adult_dvd_empire/beautiful_tits_vol_4") do
          @result = subject.fetch
        end
      end

      it { expect(@result.to_hash).to eq(expected_response.to_hash) }
    end
  end
end
