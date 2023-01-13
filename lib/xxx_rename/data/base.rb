# frozen_string_literal: true

module XxxRename
  module Data
    class Base < Dry::Struct
      transform_keys(&:to_sym)

      # resolve default types on nil
      # https://dry-rb.org/gems/dry-struct/1.0/recipes/#resolving-default-values-on-code-nil-code
      transform_types do |type|
        if type.default?
          type.constructor do |value|
            value.nil? ? Dry::Types::Undefined : value
          end
        else
          type
        end
      end

      # Until there's an easier way to convert a hash keys to string
      # without using any external library, the performance penalty
      # that comes from using `JSON.parse(hash.to_json)` is the
      # better alternative to adding more dependencies to this project
      def to_h(stringify_keys: false)
        if stringify_keys
          hash = super()
          JSON.parse(hash.to_json)
        else
          super()
        end
      end
    end
  end
end
