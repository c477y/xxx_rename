module XxxRename
  class Action
    def initialize(site_client)
      @site_client = site_client
    end

    def rename_action(hash, file, **options)
      return if XxxRename::Utils.already_processed?(file)

      new_file_name = @site_client.create_file_name(hash, file)
      if options[:save]
        print "File Match: #{file.to_s.colorize(:red)} renamed to #{new_file_name.to_s.colorize(:green)}\n"
        begin
          # Update the modified time of the file to the date the scene was
          # released and keep the accessed time as it is
          File.utime(File.atime(file), hash[:date_released], file)

          # Rename the file
          File.rename(file, new_file_name)

          # Record the output
          options[:output].add(Dir.pwd, file, new_file_name, true)
        rescue Errno::ENAMETOOLONG
          # This should not happen. `create_file_name` should ideally
          # make sure that the file name is not too long
          # In the event this error happens anyways, don't kill
          # the application
          print "Generated name is too long. Skip processing.\n"
        end
      else
        print "File Match: #{file.to_s.colorize(:red)} can be renamed to #{new_file_name.to_s.colorize(:green)}\n"
      end
    end

    def print_action(hash, file, **options)
      site_client = options[:site_client]
      print "File: #{file.to_s.colorize(:red)} response: #{hash}\n"
    end
  end
end
