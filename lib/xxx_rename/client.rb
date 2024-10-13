# frozen_string_literal: true

module XxxRename
  class Client
    #
    # Rename file(s) in the current directory
    #
    # @param [Boolean] nested
    # @param [String, Nil] checkpoint
    def initialize(nested: false, checkpoint: nil)
      @nested = nested
      @checkpoint = checkpoint
      @checkpoint_reached = false
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
      XxxRename.config.site_client_matcher
    end

    def resolver
      @resolver ||= Actions::Resolver.new
    end

    private

    attr_reader :nested, :object, :checkpoint, :checkpoint_reached

    def process_directory
      scanner.each do |file|
        if checkpoint
          if checkpoint != file && !checkpoint_reached
            XxxRename.logger.debug "[SKIP CHECKPOINT] #{file}"
            next
          elsif checkpoint == file
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
        XxxRename.logger.info "[FILE SCAN] #{file}"
        search_engine.search(file) do |search_result|
          next if search_result&.empty?

          XxxRename.config.actions.each do |action_str|
            action = resolver.resolve!(action_str)
            action.perform(Dir.pwd, file, search_result)
          end

          next unless @custom_action

          @custom_action.call(Dir.pwd, file, search_result)
        end
      end
    end

    def search_engine
      @search_engine ||= Search.new
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
