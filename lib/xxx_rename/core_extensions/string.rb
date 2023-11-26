# frozen_string_literal: true

module XxxRename
  module CoreExtensions
    module String
      # Remove the following characters from the input string and returns
      # it in lower case
      #
      # \s : whitespace characters
      # \W : any non-word character
      # _  : underscore
      #
      # @return [String]
      def normalize
        gsub(/[\s\W_]/, "").downcase
      end

      #
      # Attempt to denormalize a normalized string using a source string
      # @param [String] source_str
      # @return [String, Nil]
      def denormalize(source_str)
        res = ""
        normalized_str_idx = 0
        source_str.each_char do |source_char|
          break if normalized_str_idx >= length

          if source_char.casecmp?(self[normalized_str_idx])
            res += source_char
            normalized_str_idx += 1
          elsif source_char.match?(/[\s\W_]/) && !res.empty?
            res += source_char
          elsif !source_char.match?(/[\s\W_]/)
            res = ""
            normalized_str_idx = 0
          else
            next
          end
        end
        res.presence
      end

      def n_substring?(str)
        normalize.include?(str.normalize)
      end

      def n_substring_either?(str)
        normalize.include?(str.normalize) || str.normalize.include?(normalize)
      end

      def n_match?(str)
        normalize == str.normalize
      end

      # @return [String]
      def titleize_custom
        re = /([A-Z]\d[A-Z]|[A-Z][a-zA-Z])/
        res = []
        scan(re) { |_| res << Regexp.last_match.offset(0)[0] }
        res.reverse.each { |index| insert(index, " ") }
        strip
      end

      # Remove any characters not included in the following list
      # \w [a-zA-Z0-9_].
      # \s Whitespace character
      # - hyphen
      # , comma
      # [ brackets
      # ] brackets
      def remove_special_characters
        gsub(/[^\w\s\-,\[\]']/, "").gsub(/\s{2,}/, " ")
      end
    end
  end
end
