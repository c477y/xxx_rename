# frozen_string_literal: true

require "set"

module XxxRename
  module Data
    module Types
      include Dry.Types()

      Set = Types.Constructor(Set, Set.method(:new))
    end
  end
end
