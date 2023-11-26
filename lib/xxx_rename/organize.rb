# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "xxx_rename/data/stats_hash"

module XxxRename
  class Organize
    include FileUtilities

    delegate :actors_datastore, :scene_datastore, to: :@config

    attr_reader :config, :dry_run, :force, :source_dir, :destination_dir

    # @param [Data::Config] config
    # @param [Boolean] force
    # @param [String] source_dir
    # @param [String] destination_dir
    # @raise ArgumentError if directory does not exist
    def initialize(config, source_dir:, destination_dir:, force: false)
      @config = config
      @source_dir = validate_path!(source_dir)
      @destination_dir = validate_path!(destination_dir)
      @force = force
      XxxRename.logger.info "[SOURCE DIR] #{@source_dir}"
      XxxRename.logger.info "[DESTINATION DIR] #{@destination_dir}"
    end

    # @param [Boolean] dry_run
    # @param [Integer] minimum_scenes_threshold
    def organize(dry_run = true, minimum_scenes_threshold = 5)
      scanner.each do |file|
        primary_actor = stats.primary_actor(file).presence

        if primary_actor.nil?
          XxxRename.logger.info "[FILE MOVE SKIPPED] #{file.colorize(:light_blue)}\n" \
                                  "\t[REASON] No actor detected"
          next
        end

        move_dir = File.join(destination_dir, primary_actor)

        if valid_dir?(move_dir)
          XxxRename.logger.info "[FILE MOVE CALCULATED]\n" \
                                  "\t[SOURCE] #{file.colorize(:light_yellow)}\n" \
                                  "\t[DESTINATION] #{move_dir.colorize(:light_green)}"
          move_file!(file, move_dir, dry_run)
        elsif stats.scene_count(primary_actor) >= minimum_scenes_threshold
          XxxRename.logger.info "[FILE MOVE CALCULATED]\n" \
                                  "\t[SOURCE] #{file.colorize(:light_yellow)}\n" \
                                  "\t[DESTINATION] #{move_dir.colorize(:light_green)} (NEW DIRECTORY)"

          move_file!(file, move_dir, dry_run)
        elsif stats.scene_count(primary_actor) <= minimum_scenes_threshold
          XxxRename.logger.info "[FILE MOVE SKIPPED] #{file.colorize(:light_blue)}\n" \
                                  "\t[REASON] Primary Actor \"#{primary_actor}\" scene count " \
                                  "#{stats.scene_count(primary_actor).to_s.colorize(:light_red)} < " \
                                  "#{minimum_scenes_threshold.to_s.colorize(:light_green)}"
        end
      end
    end

    def gather_stats
      scanner.each { |file| match_actor(file) }
      stats.statistics
    end

    private

    def match_actor(file)
      abs_path = File.expand_path(file)
      scene_data = config.scene_datastore.find_by_abs_path?(abs_path)

      if scene_data.present?
        female_actors(scene_data).tap { |actors| stats.increment(file, actors) }
        return
      end

      if force
        force_match(file).tap { |actors| stats.increment(file, actors) if actors.length.positive? }
        return
      end

      XxxRename.logger.info "[NO MATCH] #{file}"
    end

    # Brute-force a match by checking presence of all actors in the filename
    # This is very inefficient, but will work for most cases
    #
    # @param [String] file
    # @return [Array<String>]
    def force_match(file)
      normalized_file = file.normalize
      all_female_actors.select { |normalized_actor| normalized_file.include?(normalized_actor) }
                       .map { |normalized_actor| normalized_actor.denormalize(file) }
    end

    # @param [Data::SceneData] scene_data
    # @return [Array<String>]
    def female_actors(scene_data)
      filter_female_actors(scene_data.actors) if scene_data.female_actors.length.zero?

      scene_data.female_actors
    end

    # @param [Array<String>] actors
    # @return [Array<String>]
    def filter_female_actors(actors)
      actors.select { |actor| actors_datastore.female?(actor) }
    end

    def validate_path!(dir)
      path = File.expand_path(dir)
      raise ArgumentError, "expanded path #{path} invalid" unless valid_dir?(path)

      path
    end

    #
    # Return an array of all actor names in normalized form
    # @return [Array<String>]
    def all_female_actors
      actors_datastore.all.fetch(:FEMALE, [])
    end

    def move_file!(file, destination, dry_run)
      source = File.join(source_dir, file)
      verbose = XxxRename.logger.level == Logger::DEBUG

      FileUtils.mkdir_p(destination, verbose: verbose, noop: dry_run) unless Dir.exist?(destination)
      FileUtils.mv(source, destination, verbose: verbose, noop: dry_run)
    end

    def scanner
      @scanner ||= FileScanner.new(source_dir, nested: false)
    end

    def stats
      @stats ||= Data::StatsHash.new
    end
  end
end
