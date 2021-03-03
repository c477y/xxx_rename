module XxxRename
  class ProcessedFile
    def initialize(file)
      @basename = File.basename(file, ".*")
    end

    def female_actors
      @basename
        .split("[F]")
        .last
        .split("[M]")
        .first
        .to_s
        .split(",")
        .map(&:strip)
        .sort
    end

    # TODO: Split on [C] collection
    def male_actors
      @basename
        .split("[M]")
        .last
        .to_s
        .split(",")
        .map(&:strip)
        .sort
    end

    def title
      @basename
        .split("[F]")
        .first
        .strip
    end
  end
end
