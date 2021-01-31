# frozen_string_literal: true

module XxxRename
  class SearchByPerformer
    def initialize(output, dir, site)
      @output = output
      @site = site
      site_client(site)

      scan_dir(dir)
    end

    private

    def site_client(site)
      @site_client ||=
        begin
          case site
          when "bz"
            XxxRename::SceneByFile::Brazzers.new
          when "dp"
            XxxRename::SceneByFile::DigitalPlayground.new
          else
            raise "invalid site name #{@site}"
          end
        end
    end

    def match(scenes, files)
      unprocessed_files = files.reject { |f| XxxRename::Utils.already_processed? f }
      unprocessed_files.each do |f|
        scene_name = File.basename(f, ".*").split("_").first.to_s
        normalized_scene_name = XxxRename::Utils.normalize(scene_name)

        if scenes[normalized_scene_name].nil?
          print "No match found for file #{f.to_s.colorize(:red)}\n"
          next
        end

        new_file_name = @site_client.create_file_name(scenes[normalized_scene_name], f)

        print "File Match: #{f.to_s.colorize(:red)} renamed to #{new_file_name.to_s.colorize(:green)}\n"
        @output.add(Dir.pwd, f, new_file_name, true)
        File.rename(f, new_file_name)
      end
    end

    def scan_dir(base_dir)
      Dir.chdir(base_dir) do
        sub_dirs = Dir["*"].select { |o| File.directory?(o) }
        sub_dirs.sort.each do |dir|
          print "Actor name: #{dir.to_s.colorize(:blue)}\n"
          Dir.chdir(dir) do
            # Get all files
            files = Dir.glob("*.mp4").sort

            # Get all scenes for the actor
            begin
              scenes = @site_client.find_all_scenes_by_actor(dir)
              match(scenes, files)
            rescue SearchError => e
              print "Unable to fetch details for #{dir}. Find error details in `error_dump.txt`\n".colorize(:red)
              e.dump_error
            end
          end
        end
      end
    end
  end
end
