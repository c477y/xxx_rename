# frozen_string_literal: true

module XxxRename
  module Data
    class FilePreProcessorRule < Base
      attribute :regex, Types::String
      attribute :with, Types::String

      DEFAULT_RULES = [
        new(
          {
            regex: "[^[:ascii:]]",
            with: ""
          }
        ).to_h,
        new(
          {
            regex: "\s+",
            with: " "
          }
        ).to_h
      ].freeze

      def replace(file)
        # At the point, the regexp will be validate by the contract
        # We don't expect this to raise any RegexpError
        re = Regexp.new(regex)
        file.gsub(re, with)
      end
    end
  end
end
