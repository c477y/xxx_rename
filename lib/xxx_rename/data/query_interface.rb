# frozen_string_literal: true

module XxxRename
  module Data
    class QueryError < StandardError
      def initialize(scene_data)
        @scene_data = scene_data
        super(message)
      end
    end

    class UniqueRecordViolation < QueryError
      def message
        "Scene already present in database: #{@scene_data.inspect}"
      end
    end

    class RecordNotFound < QueryError
      def message
        "Scene not saved in database #{@scene_data.inspect}"
      end
    end

    class QueryInterface
      # @param [PStore] store
      # @param [Mutex] semaphore
      def initialize(store, semaphore)
        @store = store
        @semaphore = semaphore
      end

      def find(*)
        raise "Not Implemented"
      end

      def create!(*)
        raise "Not Implemented"
      end

      def upsert(*)
        raise "Not Implemented"
      end

      def destroy!(*)
        raise "Not Implemented"
      end

      def count(*)
        raise "Not Implemented"
      end

      def metadata(*)
        raise "Not Implemented"
      end

      def update_metadata(*)
        raise "Not Implemented"
      end

      def all
        raise "Not Implemented"
      end

      # @param [Array[String|Integer]] strs
      def generate_lookup_key(*strs)
        strs.map(&:to_s).map { |x| sanitize(x) }.join("$")
      end

      attr_reader :store

      private

      attr_reader :semaphore

      # @param [String] str
      # @return [String]
      def sanitize(str)
        str.to_s.normalize
      end

      def benchmark(opr = "unnamed")
        raise "#benchmark called without block" unless block_given?

        resp = nil
        time = Benchmark.measure { resp = yield }
        XxxRename.logger.debug "#{"[BENCHMARK]".colorize(:cyan)} #{self.class.name}##{opr}: #{time.real.round(3)}s"
        resp
      end
    end
  end
end
