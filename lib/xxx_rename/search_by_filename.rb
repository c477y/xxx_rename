# frozen_string_literal: true

module XxxRename
  class SearchByFilename
    def initialize(output, **options)
      @output = output
      @save = options[:save]
      @nested = options[:nested]
      @force = options[:force]

      @site_client = options[:site_client]
      @matcher = XxxRename::SceneMatcher.new(@site_client)
    end

    def process(object, proc)
      @proc = proc

      process_file(object) if File.file?(object)

      process_directory(object, @nested) if File.directory?(object)
    end

    private

    def process_directory(dir, nested)
      options = { nested: nested }
      scanner = XxxRename::FileScanner.new(dir, **options)
      scanner.each do |file|
        process_file(file)
      end
    end

    def process_file(file)
      return if XxxRename::Utils.already_processed?(file) && !@force

      scene = @matcher.match(file)
      if scene.nil?
        print "No match found for file #{file.to_s.colorize(:red)}. Skipping this file...\n"
        return nil
      end
      options = { save: @save, output: @output, site_client: @site_client }
      @proc.call(scene, file, **options)
    end
  end
end
