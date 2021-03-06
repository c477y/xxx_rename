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

    def verbose_action(hash, file, **_options)
      print "File: #{file.to_s.colorize(:red)} response: #{hash}\n"
    end

    def modify_date_action(hash, file, **options)
      original_mtime = File.mtime(file).strftime("%d/%m/%Y")
      new_mtime = hash[:date_released].strftime("%d/%m/%Y")
      return if original_mtime == new_mtime

      if options[:save]
        print "File Match: #{file.to_s.colorize(:red)} : original modified date is \
#{original_mtime.to_s.colorize(:green)}. Modified to \
#{new_mtime.to_s.colorize(:green)}\n"
        File.utime(File.atime(file), hash[:date_released], file)
      else
        print "File Match: #{file.to_s.colorize(:red)} : original modified date is \
#{original_mtime.to_s.colorize(:green)}. It can be set to \
#{new_mtime.to_s.colorize(:green)}\n"
      end
    end
  end
end
