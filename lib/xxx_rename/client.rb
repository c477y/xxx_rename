# frozen_string_literal: true

require "xxx_rename/contract/file_rename_op_contract"
require "xxx_rename/data/file_rename_op_datastore"
require "xxx_rename/site_client_matcher"
require "xxx_rename/actions/resolver"

module XxxRename
  class Client
    #
    # Rename file(s) in the current directory
    #
    # @param [Data::Config] config
    # @param [Boolean] verbose
    # @param [Symbol] override_site
    # @param [Boolean] nested
    # @param [String, Nil] checkpoint
    def initialize(config, verbose:, override_site: nil, nested: false, checkpoint: nil)
      @config = config
      @override_site = override_site
      @nested = nested
      @checkpoint = checkpoint
      @checkpoint_reached = false
      XxxRename.logger(verbose: verbose)
    end

    def generate(object, &block)
      @object = object
      @custom_action = block
      if File.directory?(object)
        process_directory
        return
      end

      if File.file?(object)
        process_file(object)
        return
      end

      raise Errors::FatalError, "[UNKNOWN OBJECT #{object}] pass a valid file or directory"
    end

    def matcher
      @matcher ||=
        begin
          m = SiteClientMatcher.new(config, override_site: override_site)
          ActorsHelper.instance.matcher(m)
          m
        end
    end

    def resolver
      @resolver ||= Actions::Resolver.new(config)
    end

    private

    attr_reader :config, :override_site, :nested, :object

    def process_directory
      scanner.each do |file|
        if @checkpoint
          if @checkpoint != file && !@checkpoint_reached
            XxxRename.logger.debug "[SKIP CHECKPOINT] #{file}"
            next
          elsif @checkpoint == file
            XxxRename.logger.info "[REACHED CHECKPOINT] #{file}"
            @checkpoint_reached = true
          end
        end
        process_file(file)
      end
    end

    def process_file(file)
      path = relative_path(file)
      file = File.basename(file)

      Dir.chdir(path) do
        XxxRename.logger.info "#{"[FILE SCAN]".colorize(:blue)} #{file}"
        search_engine.search(file) do |search_result|
          next if search_result&.empty?

          config.actions.each do |action_str|
            action = resolver.resolve!(action_str)
            action.perform(Dir.pwd, file, search_result)
          end

          next unless @custom_action

          @custom_action.call(Dir.pwd, file, search_result)
        end
      end
    end

    def search_engine
      @search_engine ||= Search.new(matcher, config.scene_datastore, config.force_refresh)
    end

    def scanner
      @scanner ||= FileScanner.new(@object, nested: @nested)
    end

    def relative_path(file)
      return Dir.pwd if File.basename(file) == file

      file.gsub(File.basename(file), "")
    end
  end
end
