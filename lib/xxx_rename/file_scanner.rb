# frozen_string_literal: true

module XxxRename
  class FileScanner
    #
    # Create a new Scanner
    #
    # @param [String] dir Directory to be processed
    # @param [Hash] options
    # @option options [Boolean] :nested Specify if nested directories should be scanned
    # @option options [String] extension Extension of filenames to be selected
    def initialize(dir, **options)
      @nested = options[:nested]
      @extension = options[:extension].nil? ? "*.{mp4,f4v,mkv,avi,wmv,flv}" : options[:extension]
      @dir = dir
    end

    # @param [Proc] block Block of code to be executed for each file
    def each(&block)
      @block = block
      process_directory(@dir)
    end

    private

    #
    # Executes a block of code for all files in a given directory. Will scan files
    # in sub-directories if @nested is passed as true
    #
    # @param [String] dir Directory path to scan
    def process_directory(dir)
      Dir.chdir(dir) do
        # Process files in a given directory
        XxxRename.logger.info "#{"[DIRECTORY SCAN]".colorize(:blue)} #{Dir.pwd}"

        Dir.glob(@extension).sort.each { |file| @block.call(file) }

        # Return unless we want to scan the directories inside
        # the directory `dir`
        return unless @nested

        nested_dir = Dir["*"].select { |o| File.directory?(o) }
        nested_dir.sort.each do |each|
          process_directory(each)
        end
      end
    end
  end
end
