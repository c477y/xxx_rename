# frozen_string_literal: true

module XxxRename
  module Data
    class StatsHash

      # Primary method to register a statistic
      # @param [Array<String>] actors
      # @param [String] file
      def increment(file, actors)
        raise ArgumentError, "File should have at least one actor" if actors.length.zero?

        normalized_actors = actors.map { |x| normalize_actor(x) }

        normalized_actors.each { |normalized_actor| increment_actor(normalized_actor) }

        file_to_normalized_actors_counter[file] = normalized_actors
      end

      # @param [String] file
      # @return [String, NilClass]
      def primary_actor(file)
        raise ArgumentError, "File not registered in statistics" unless file_to_normalized_actors_counter.key?(file)

        normalized_actors = file_to_normalized_actors_counter[file]
        primary_actor = normalized_actors&.max_by { |actor| normalized_actor_to_scene_counter[actor] }
        actor_name(primary_actor)
      end

      def scene_count(actor)
        normalized_actor_to_scene_counter.fetch(actor.normalize, 0)
      end

      def statistics
        normalized_actor_to_scene_counter
          .transform_keys { |normalized_actor| actor_name(normalized_actor) }
          .sort_by { |_, v| v }
          .reverse
          .to_h
      end

      private

      def increment_actor(normalized_actor)
        normalized_actor_to_scene_counter[normalized_actor] = if normalized_actor_to_scene_counter.key?(normalized_actor)
                                                     normalized_actor_to_scene_counter[normalized_actor] + 1
                                                   else
                                                     1
                                                   end
      end

      def actor_name(normalized_actor)
        normalized_actor_name_lookup[normalized_actor]
      end

      # Hash lookup: File Name -> Array of (Normalized) Actors
      # @return [Hash]
      def file_to_normalized_actors_counter
        @file_to_normalized_actors_counter ||= {}
      end

      # Hash lookup: (Normalized) Actor -> Scene Count
      # @return [Hash]
      def normalized_actor_to_scene_counter
        @normalized_actor_to_scene_counter ||= {}
      end

      # Hash lookup: (Normalized) Actor Name -> Actor Name
      # @return [Hash]
      def normalized_actor_name_lookup
        @normalized_actor_name_lookup ||= {}
      end

      # Accepts a actor name and returns the normalized version
      # The actor name is also inserted into a lookup hash
      # @param [String] actor
      # @return [String] normalized actor name
      def normalize_actor(actor)
        normalized_str = actor.normalize
        normalized_actor_name_lookup[normalized_str] = actor
        normalized_str
      end
    end
  end
end
