# frozen_string_literal: true

module XxxRename
  module Data
    module Types
      include Dry.Types()

      Set = Types.Constructor(Set, Set.method(:new))
      StrippedString = Types.Constructor(String, &:strip)
    end
  end
end
