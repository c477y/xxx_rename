# frozen_string_literal: true

module XxxRename
  module Data
    class StashAppPerformerData < Base
      attribute :name, Types::String
      attribute? :gender, Types::String.optional
    end

    class StashAppSceneFragment < Base
      attribute :id, Types::String
      attribute :title, Types::String
      attribute :performers, Types::Array.of(StashAppPerformerData).default([].freeze)
      attribute? :details, Types::String.optional
      attribute? :director, Types::String.optional
      attribute? :urls, Types::String.optional
      attribute? :date, Types::String.optional
    end
  end
end
