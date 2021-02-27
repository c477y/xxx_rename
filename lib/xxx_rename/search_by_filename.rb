# frozen_string_literal: true

module XxxRename
  class SearchByFilename
    def initialize(output, object, site, save)
      @output = output
      @save = save

      site_client(site)

      process_file object if File.file? object

      process_directory object if File.directory? object
    end

    private

    def process_directory(root_dir)
      process_files_in_directory(root_dir)
      Dir.chdir(root_dir) do
        process_sub_dirs_in_directory
      end
    end

    def process_files_in_directory(root_dir)
      print "Scanning files in #{Dir.pwd}\n".colorize(:blue)
      Dir.chdir(root_dir) do
        process_files_in_current_dir
      end
    end

    def process_sub_dirs_in_directory
      print "Scanning sub-directories in #{Dir.pwd}\n".colorize(:blue)
      sub_dirs = Dir["*"].select { |o| File.directory?(o) }
      sub_dirs.sort.each do |dir|
        print "Scanning files in #{dir}\n".colorize(:blue)
        Dir.chdir(dir) do
          # Scan the files in the sub-directory
          process_files_in_current_dir

          # Then call the parent function if there are any
          # sub-directories inside this sub-directory
          repeat_dirs = Dir["*"].select { |o| File.directory?(o) }
          repeat_dirs.sort.each do |rd|
            Dir.chdir(rd) do
              process_sub_dirs_in_directory
            end
          end
        end
      end
    end

    def site_client(site)
      @site_client ||=
        begin
          case site
          when "bz"
            XxxRename::SceneByFile::Brazzers.new
          when "dp"
            XxxRename::SceneByFile::DigitalPlayground.new
          when "rk"
            XxxRename::SceneByFile::RealityKings.new
          else
            raise "invalid site name #{@site}"
          end
        end
    end

    def process_files_in_current_dir
      files = Dir.glob("*.mp4")
      files.sort.each do |file|
        process_file(file)
      end
    end

    def process_file(file)
      return if XxxRename::Utils.already_processed?(file)

      begin
        scenes = @site_client.search(file, 1)
        if matching_scenes?(scenes, file)
          search_and_process_match(scenes, file)
          return
        end

        print "No match found for file #{file.to_s.colorize(:red)}. Trying again with more search results...\n"
        scenes = @site_client.search(file, 10)
        if matching_scenes?(scenes, file)
          search_and_process_match(scenes, file)
          return
        end

        print "Still no match found for file #{file.to_s.colorize(:red)}. Skipping this file...\n"
      rescue SearchError => e
        print "Unable to rename file #{file}. Find error details in `error_dump.txt`\n".colorize(:red)
        e.dump_error
      end
    end

    def search_and_process_match(scenes, file)
      scene_name = XxxRename::Utils.scene_name file
      normalized_scene_name = XxxRename::Utils.normalize scene_name
      process_successful_match(scenes[normalized_scene_name], file)
    end

    def matching_scenes?(scenes, file)
      scene_name = XxxRename::Utils.scene_name file
      normalized_scene_name = XxxRename::Utils.normalize scene_name
      !scenes[normalized_scene_name].nil?
    end

    def process_successful_match(scene, file)
      new_file_name = @site_client.create_file_name(scene, file)
      if @save
        print "File Match: #{file.to_s.colorize(:red)} renamed to #{new_file_name.to_s.colorize(:green)}\n"
        begin
          File.rename(file, new_file_name)
          @output.add(Dir.pwd, file, new_file_name, true)
        rescue Errno::ENAMETOOLONG
          print "Generated name is too long. Skip processing.\n"
          @output.add(Dir.pwd, file, file, false)
        end
      else
        print "File Match: #{file.to_s.colorize(:red)} can be renamed to #{new_file_name.to_s.colorize(:green)}\n"
      end
    end
  end
end
