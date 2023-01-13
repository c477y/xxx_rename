# frozen_string_literal: true

require "base64"

require "xxx_rename/errors"
require "xxx_rename/integrations/base"
require "xxx_rename/file_utilities"

module XxxRename
  module Integrations
    class StashAPIError < StandardError
      def initialize(errors)
        @errors = errors
        super(message)
      end

      def message
        msg = "Stash API returned error:\n"
        @errors.each do |e|
          s  = "\tMESSAGE #{e["message"]}\n"
          s += "\tOPERATION #{e["path"]} \n"
          msg += s
        end
        msg
      end
    end

    class StashApp < Base
      include FileUtilities

      GRAPHQL_ENDPOINT = "/graphql"

      def initialize(config)
        super(config)
        raise Errors::FatalError, "Stash App requires 'url'. Check your configuration." unless config.stash_app.url.presence

        self.class.base_uri(config.stash_app.url)
        self.class.headers("Content-Type" => "application/json")
      end

      def setup_credentials!
        register_api_key(stash_app_config.api_token) if api_key_provided?

        validate_credentials!
      end

      def fetch_studio(name)
        response = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: find_studio_body(name)) }
        response.dig("data", "findStudios", "studios")&.select { |x| x["name"].normalize == name.normalize }&.first
      end

      def fetch_movie(name)
        response = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: fetch_movie_body(name)) }
        response.dig("data", "findMovies", "movies")&.select { |x| x["name"].normalize == name.normalize }&.first
      end

      def create_movie(scene_data, studio_id, retried = false)
        return if scene_data.movie.nil?

        response = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: create_movie_body(scene_data.movie, studio_id)) }
        raise StashAPIError, response["errors"] if response["errors"]

        response.dig("data", "movieCreate")
      rescue StashAPIError => e
        # re-raise if already retried
        raise e if retried

        # as of current implementation, movie creation fails if the image url is invalid
        # retry again and don't set the back image. consecutive failures will be raised
        XxxRename.logger.error "[STASH APP MOVIE CREATION RETRY] without back image"
        hash = scene_data.to_h.tap do |h|
          h[:movie] = h[:movie].tap { |m_h| m_h.delete(:back_image) }
        end
        new_scene_data = Data::SceneData.new(hash)
        create_movie(new_scene_data, studio_id, true)
      end

      def fetch_scene(path)
        response = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: fetch_scene_body(path)) }
        scenes = response.dig("data", "findScenes", "scenes")
        scenes.length == 1 ? scenes.first : nil
      end

      def update_scene(scene_id, movie_id)
        response = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: update_scene_body(scene_id, movie_id)) }
        raise StashAPIError, response["errors"] if response["errors"]

        response.dig("data", "sceneUpdate")
      end

      private

      def update_scene_body(scene_id, movie_id)
        {
          operationName: "SceneUpdate",
          variables: {
            input: {
              id: scene_id,
              movies: [
                { "movie_id": movie_id, "scene_index": nil }
              ]
            }
          },

          query: <<~GRAPHQL
            mutation SceneUpdate($input: SceneUpdateInput!) {
              sceneUpdate(input: $input) {
                id
                title
                files {
                  path
                }
                movies {
                  movie {
                    id
                    name
                    front_image_path
                  }
                  scene_index
                }
              }
            }
          GRAPHQL
        }.to_json
      end

      def fetch_scene_body(path)
        {
          operationName: "FindScenes",
          variables: {
            filter: {
              per_page: 2
            },
            scene_filter: {
              path: {
                modifier: "INCLUDES",
                value: "\"#{path}\""
              }
            }
          },
          query: <<~GRAPHQL
            query FindScenes($filter: FindFilterType, $scene_filter: SceneFilterType, $scene_ids: [Int!]) {
              findScenes(filter: $filter, scene_filter: $scene_filter, scene_ids: $scene_ids) {
                scenes {
                  id
                  title
                  files {
                    path
                  }
                  movies {
                      movie {
                        id
                        name
                        front_image_path
                      }
                      scene_index
                  }
                }
              }
            }
          GRAPHQL
        }.to_json
      end

      def create_movie_body(movie, studio_id)
        variables = {}.tap do |h|
          h[:name]        = movie.name
          h[:date]        = movie.date&.strftime("%Y-%m-%d") if movie.date
          h[:url]         = movie.url                        if movie.url
          h[:front_image] = movie.front_image
          h[:back_image]  = movie.back_image                 if movie.back_image
          h[:studio_id]   = studio_id                        if studio_id
          h[:synopsis]    = movie.synopsis                   if movie.synopsis
        end

        {
          operationName: "MovieCreate",
          variables: variables,
          query: <<~GRAPHQL
            mutation MovieCreate(
              $name: String!
              $aliases: String
              $duration: Int
              $date: String
              $rating: Int
              $studio_id: ID
              $director: String
              $synopsis: String
              $url: String
              $front_image: String
              $back_image: String
            ) {
              movieCreate(
                input: {
                  name: $name
                  aliases: $aliases
                  duration: $duration
                  date: $date
                  rating: $rating
                  studio_id: $studio_id
                  director: $director
                  synopsis: $synopsis
                  url: $url
                  front_image: $front_image
                  back_image: $back_image
                }
              ) {
                id
                name
                duration
                date
                director
                studio {
                  id
                  name
                }
                synopsis
                url
                front_image_path
                back_image_path
              }
            }
          GRAPHQL
        }.to_json
      end

      def fetch_movie_body(name)
        {
          operationName: "FindMovies",
          variables: {
            filter: {
              per_page: 5
            },
            movie_filter: {
              name: {
                modifier: "EQUALS",
                value: name
              }
            }
          },
          query: <<~GRAPHQL
            query FindMovies($filter: FindFilterType, $movie_filter: MovieFilterType) {
              findMovies(filter: $filter, movie_filter: $movie_filter) {
                movies {
                  id
                  name
                  scenes {
                    id
                    title
                    path
                  }
                }
              }
            }
          GRAPHQL
        }.to_json
      end

      def find_studio_body(name)
        {
          operationName: "FindStudios",
          variables: {
            filter: {
              per_page: 5
            },
            studio_filter: {
              name: {
                modifier: "EQUALS",
                value: name
              }
            }
          },
          query: <<~GRAPHQL
            query FindStudios($filter: FindFilterType, $studio_filter: StudioFilterType) {
              findStudios(filter: $filter, studio_filter: $studio_filter) {
                studios {
                  id
                  name
                }
              }
            }
          GRAPHQL
        }.to_json
      end

      def register_api_key(api_token)
        @api_key_set = true
        self.class.headers "ApiKey" => api_token
      end

      def api_key_provided?
        stash_app_config.api_token.to_s.presence.is_a?(String)
      end

      def validate_credentials!
        body = {
          operationName: "Version",
          query: <<~GRAPHQL
            query Version {
              version {
                version
              }
            }
          GRAPHQL
        }.to_json

        resp = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: body) }
        resp.dig("data", "version", "version")
      end

      def stash_app_config
        config.stash_app
      end
    end
  end
end
