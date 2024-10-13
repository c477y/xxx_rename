# frozen_string_literal: true

module XxxRename
  module Data
    class SceneMovieData < Base
      attribute :name, Types::String
      attribute? :date, Types::Time
      attribute? :url, Types::String
      attribute :front_image, Types::String
      attribute? :back_image, Types::String
      attribute :studio, Types::String
      attribute? :synopsis, Types::String
    end
  end
end
