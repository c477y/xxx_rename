# frozen_string_literal: true

require "rspec"

describe XxxRename::SiteClients::StashDb do
  include_context "config provider"
  subject { described_class.new }

  describe "#setup_credentials" do
    context "when using api token" do
      let(:override_config) { { "site" => { "stash" => { "api_token" => api_token } } } }

      context "successful login" do
        let(:api_token) { ENV.fetch("XXX_RENAME_STASH_DB_API_KEY", "valid_api_token") }

        before do
          VCR.use_cassette("stash/login#api_key#success") do
            @result = subject.setup_credentials!
          end
        end

        it "returns the version" do
          expect(@result).to eq("v0.5.3")
        end
      end

      context "unsuccessful login" do
        let(:api_token) { "invalid_api_token" }

        it "raises api exception" do
          expect do
            VCR.use_cassette("stash/login#api_key#fail") do
              @result = subject.setup_credentials!
            end
          end.to raise_error(XxxRename::SiteClients::Errors::APIError)
        end
      end
    end

    context "when using username/password" do
      pending "works, but tests need fixing"
      # let(:override_config) { { "site" => { "stash" => { "username" => username, "password" => password } } } }
      #
      # context "given correct credentials" do
      #   let(:username) { ENV.fetch("XXX_RENAME_STASH_DB_USERNAME", "foo") }
      #   let(:password) { ENV.fetch("XXX_RENAME_STASH_DB_PASSWORD", "bar") }
      #
      #   before do
      #     VCR.use_cassette("stash/login#username_password#success") do
      #       @result = subject.setup_credentials!
      #     end
      #   end
      #
      #   it "should return a valid cookie" do
      #     expect(@result).to match(/session=\w*/)
      #   end
      # end
      #
      # context "given in-correct credentials" do
      #   let(:username) { "foo" }
      #   let(:password) { "bar" }
      #
      #   it "raise correct error" do
      #     expect do
      #       VCR.use_cassette("stash/login#username_password#fail") do
      #         @result = subject.setup_credentials!
      #       end
      #     end.to raise_error(XxxRename::SiteClients::Errors::UnauthorizedError)
      #   end
      # end
    end
  end

  describe "#actor_details" do
    let(:name) { "Angela White" }
    context "when no credentials are provided" do
      it "returns immediately and does not call any APIs" do
        expect(subject.actor_details(name)).to be nil
      end
    end

    context "with valid credentials" do
      let(:api_token) { ENV.fetch("XXX_RENAME_STASH_DB_API_KEY", "valid_api_token") }
      let(:override_config) do
        { "site" => { "stash" => { "api_token" => api_token } } }
      end

      context "when api returns a response" do
        context "successful response" do
          let(:expected_response) { { "gender" => "FEMALE", "name" => "Angela White" } }

          before do
            VCR.use_cassette("stash/actor_details#angela_white#success") do
              @result = subject.actor_details(name)
            end
          end

          it "returns the correct response" do
            expect(@result).to eq(expected_response)
          end
        end

        context "unsuccessful response" do
          let(:name) { "foo" }

          before do
            VCR.use_cassette("stash/actor_details#foo#success") do
              @result = subject.actor_details(name)
            end
          end

          it "returns the correct response" do
            expect(@result).to be nil
          end
        end
      end
    end
  end

  describe "#search" do
    let(:override_config) do
      { "site" => { "stash" => { "api_token" => api_token, "file_source_format" => ["%female_actors - %title"] } } }
    end
    let(:api_token) { ENV.fetch("XXX_RENAME_STASH_DB_API_KEY", "valid_api_token") }
    let(:filename) { "Bombshell Scarlett Gets Flawless Ass Filled Up.mp4" }
    let(:parsed_scene_data) do
      XxxRename::Data::ParsedSceneData.new(
        actors: ["Scarlett Alexis", "Christian Clay"],
        title: "Bombshell Scarlett Gets Flawless Ass Filled Up"
      )
    end

    context "when stash db matches a scene" do
      let(:expected_resp) do
        XxxRename::Data::SceneData.new(
          female_actors: ["Scarlett Alexis"],
          male_actors: ["Christian Clay"],
          actors: ["Scarlett Alexis", "Christian Clay"],
          collection: "Tushy Raw",
          collection_tag: "ST",
          title: "Bombshell Scarlett Gets Flawless Ass Filled Up",
          id: "4f24840f-08bc-4f49-8769-d4c4dc49aa65",
          date_released: Time.parse("2024-04-30"),
          director: "Derek Dozer",
          description: "Bombshell Scarlett is all for exciting activities, she just doesn't want to leave the bed to have them.",
          scene_link: "https://www.tushyraw.com/videos/bombshell-scarlett-gets-flawless-ass-filled-up",
          scene_cover: "https://cdn.stashdb.org/images/52/53/52538a65cefabb30d910c5b744aac8e9"
        )
      end

      before do
        VCR.use_cassette("stash/search#bombshell_scarlett_gets_flawless_ass_filled_up#success") do
          @result = subject.search(filename, parsed_scene_data: parsed_scene_data)
        end
      end

      it "should return scene data" do
        expect(@result).to eq(expected_resp)
      end
    end

    context "when stash db is not able to match a scene" do
      let(:parsed_scene_data) do
        XxxRename::Data::ParsedSceneData.new(title: "foobar")
      end

      it "should raise an error" do
        expect do
          VCR.use_cassette("stash/search#foobar#fail") do
            @result = subject.search("foo", parsed_scene_data: parsed_scene_data)
          end
        end.to raise_error(XxxRename::SiteClients::Errors::NoMatchError)
      end
    end
  end
end
