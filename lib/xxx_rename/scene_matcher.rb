module XxxRename
  class SceneMatcher
    def initialize(site_client)
      @site_client = site_client
    end

    def match(file)
      scene_title = XxxRename::Utils.scene_title(file)
      normalized_scene_name = XxxRename::Utils.normalize scene_title
      print "Looking up file #{file.to_s.colorize(:blue)}\n"
      search_string = XxxRename::Utils.scene_title(file)

      # Search with 1 result
      scenes = search_results(search_string, normalized_scene_name, 1)
      return scenes unless scenes.nil?

      print "Failed lookup. Trying again with more results.\n"
      # Brute force lookup. Search with 20 results
      scenes = search_results(search_string, normalized_scene_name, 50)
      return scenes unless scenes.nil?

      print "Failed lookup with more results. Trying again with smaller search string.\n"
      tmp = search_string
      while tmp != ""
        tmp = reduce_search_string(tmp)
        print "Trying with #{tmp.to_s.colorize(:blue)}\n"
        search_results(tmp, normalized_scene_name, 15)
      end

      nil
    rescue SearchError => e
      print "Unable to rename file #{file}. Find error details in `error_dump.txt`\n".colorize(:red)
      e.dump_error
      nil
    end

    private

    def reduce_search_string(search_string)
      # Remove last 2 characters
      search_string.chop.chop
    end

    def search_results(search_string, normalized_scene_name, limit)
      scenes = @site_client.search(search_string, limit)
      scenes[normalized_scene_name]
    end

    def log_failed_matches(search_string, scenes)
      print "Brute force failed. Search String:\
#{search_string.to_s.colorize(:red)}. Scenes found were: \
#{scenes.keys.map { |e| scenes[e][:title] }.join(", ").to_s.colorize(:red)}\n"
    end
  end
end
