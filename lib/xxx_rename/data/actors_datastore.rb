# frozen_string_literal: true

require "pstore"
require "benchmark"
require "pathname"

require "xxx_rename/data/query_interface"

module XxxRename
  module Data
    ACTORS_DATASTORE_DEFAULT_STORE_FILE = "xxx_rename_actors_datastore.store"

    class ActorsDatastore
      attr_reader :store

      def initialize(dir, name = ACTORS_DATASTORE_DEFAULT_STORE_FILE)
        path = File.join(dir, name)
        XxxRename.logger.debug "#{"[DATASTORE INIT]".colorize(:green)} #{path} #{name}"

        @store = PStore.new path
      end
    end

    class ActorsDatastoreQuery < QueryInterface
      def create!(actor, gender)
        gender = validate_gender!(gender)
        benchmark("create!") do
          semaphore.synchronize do
            store.transaction do
              actor_key = sanitize(actor)
              store[actor_key] = gender
            end
          end
        end
      end

      def find(actor)
        benchmark("find") do
          semaphore.synchronize do
            store.transaction do
              actor_key = sanitize(actor)
              store.fetch(actor_key, nil)
            end
          end
        end
      end

      def male?(actor)
        gender?(actor, "MALE")
      end

      def female?(actor)
        gender?(actor, "FEMALE")
      end

      def count
        benchmark("count") do
          semaphore.synchronize do
            store.transaction(true) do
              store.roots.length
            end
          end
        end
      end

      def all
        benchmark("all") do
          semaphore.synchronize do
            store.transaction(true) do
              hash = { FEMALE: [], MALE: [] }
              store.roots.each do |actor|
                hash[:FEMALE] << actor if store[actor] == "FEMALE"
                hash[:MALE]   << actor if store[actor] == "MALE"
              end
              hash
            end
          end
        end
      end

      private

      SUPPORTED_GENDERS = %w[MALE FEMALE].freeze

      def validate_gender!(gender)
        gender = gender.to_s.upcase
        return gender if SUPPORTED_GENDERS.include?(gender)

        raise ArgumentError, "expected one of #{SUPPORTED_GENDERS.join(", ")}, but got #{gender}"
      end

      def gender?(actor, gender)
        query_gender = find(actor)
        return false unless query_gender

        gender == query_gender
      end
    end
  end
end
