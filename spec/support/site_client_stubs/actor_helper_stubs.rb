# frozen_string_literal: true

module SiteClientStubs
  class ActorHelperStubs
    class << self
      include WebMock::API

      def enable
        stub_request(:get, %r{https://www.brazzers.com/})
          .to_return(status: 200,
                     headers: { "set-cookie" => "instance_token=instance_token" })
      end

      def enable_actor(actor:, gender:)
        response = {
          result: [
            {
              name: actor,
              gender: gender
            }
          ]
        }.to_json
        stub_request(:get, %r{https://site-api.project1service.com/v1/actors})
          .to_return(status: 200,
                     headers: { "Content-Type" => "application/json; charset=utf-8" },
                     body: response)
      end
    end
  end
end
