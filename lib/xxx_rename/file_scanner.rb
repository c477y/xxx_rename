module XxxRename
  class FileScanner
    def initialize(dir, **options)
      @nested = options[:nested]
      @dir = dir
    end

    def each(&block)
      @block = block
      process_directory(@dir)
    end

    private

    def process_directory(dir)
      Dir.chdir(dir) do
        # Process files in a given directory
        print "Scanning files in #{Dir.pwd}\n".colorize(:blue)

        Dir.glob("*.mp4").sort.each { |file| @block.call(file) }

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
