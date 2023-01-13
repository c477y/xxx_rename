# frozen_string_literal: true

module XxxRename
  module Contract
    module Types
      include Dry.Types()
      SanitizedString = Types::String.constructor(&:strip)
    end
  end
end
