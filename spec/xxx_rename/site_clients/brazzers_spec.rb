# frozen_string_literal: true

require "rspec"
require "xxx_rename/site_clients/brazzers"

describe XxxRename::SiteClients::Brazzers do
  include_context "config provider"

  subject(:call) do
    described_class.new(config)
  end

  let(:site_url) { "https://www.brazzers.com" }

  let(:correct_filename) { "Anal Is The Best Medicine [BZ] Doctor Adventures [F] Devon [M] James Deen.mp4" }
  let(:expected_search_response) do
    JSON.generate(
      {
        "result" => [
          {
            "id" => "1",
            "title" => "Anal Is The Best Medicine",
            "dateReleased" => "2013-12-08T00:00:00+00:00",
            "actors" => [{ "name" => "James Deen", "gender" => "male" }, { "name" => "Devon", "gender" => "female" }],
            "collections" => [{ "name" => "Doctor Adventures" }],
            "description" => "foobar"
          }
        ]
      }
    )
  end
  let(:expected_resp) do
    XxxRename::Data::SceneData.new(
      female_actors: ["Devon"],
      male_actors: ["James Deen"],
      actors: ["Devon", "James Deen"],
      collection: "Doctor Adventures",
      collection_tag: "BZ",
      title: "Anal Is The Best Medicine",
      id: 1,
      date_released: Time.parse("2013-12-08"),
      description: "foobar"
    )
  end

  before do
    allow_any_instance_of(described_class).to receive(:refresh_token_mg).with(site_url).and_return("instance token")
  end

  context "given a processed file" do
    let(:file) { correct_filename }
    context "search result on first attempt" do
      before do
        stub_request(:get, "https://site-api.project1service.com/v2/releases")
          .with(query: { limit: 10, search: "anal is the best medicine", type: "scene" })
          .to_return(status: 200, body: expected_search_response)
      end

      it "returns correct response" do
        expect(call.search(file)).to eq(expected_resp)
      end
    end
  end

  context "given an unprocessed file" do
    let(:file) { "anal-is-the-best-medicine_720p.mp4" }

    context "search result on first attempt" do
      before do
        stub_request(:get, "https://site-api.project1service.com/v2/releases")
          .with(query: { limit: 10, search: "anal is the best medicine", type: "scene" })
          .to_return(status: 200, body: expected_search_response)
      end

      it "returns correct response" do
        expect(call.search(file)).to eq(expected_resp)
      end
    end

    context "search with recursion" do
      let(:no_result_response) do
        JSON.generate(
          {
            "result" => [
              {
                "title" => "WOW",
                "dateReleased" => "2013-12-08T00:00:00+00:00",
                "actors" => [{ "name" => "Jordan Ash", "gender" => "male" },
                             { "name" => "Carmella Crush", "gender" => "female" }],
                "collections" => [{ "name" => "Baby Got Boobs" }]
              }
            ]
          }
        )
      end

      before do
        stub_request(:get, "https://site-api.project1service.com/v2/releases")
          .with(query: { limit: 10, search: "anal is the best medicine", type: "scene" })
          .to_return(status: 200, body: no_result_response)
        stub_request(:get, "https://site-api.project1service.com/v2/releases")
          .with(query: { limit: 10, search: "anal is the best med", type: "scene" })
          .to_return(status: 200, body: no_result_response)
        stub_request(:get, "https://site-api.project1service.com/v2/releases")
          .with(query: { limit: 10, search: "anal is the bes", type: "scene" })
          .to_return(status: 200, body: no_result_response)
        stub_request(:get, "https://site-api.project1service.com/v2/releases")
          .with(query: { limit: 10, search: "anal is th", type: "scene" })
          .to_return(status: 200, body: expected_search_response)
      end

      it "returns correct response on recursive attempt" do
        expect(call.search(file, recursive: true)).to eq(expected_resp)
      end
    end
  end
end
