# frozen_string_literal: true

require "csv"

module XxxRename
  class Rollback
    def initialize(filename)
      CSV.foreach(filename, { encoding: "UTF-8", headers: true, header_converters: :symbol }) do |row|
        rename_file(row.to_hash)
      end
    end

    private

    def rename_file(row)
      return if row[:old_file_name] == row[:new_file_name]

      unless File.directory? row[:path]
        print "#{row[:path].to_s.colorize(:red)} is not a valid directory.\n"
        return
      end

      unless File.file? File.join row[:path], row[:new_file_name]
        print "#{row[:new_file_name].to_s.colorize(:red)} is not a valid file.\n"
        return
      end

      Dir.chdir(row[:path]) do
        print "#{row[:new_file_name].to_s.colorize(:green)} renamed back to #{row[:old_file_name].to_s.colorize(:green)}\n"
        File.rename(row[:new_file_name], row[:old_file_name])
      end
    end
  end
end
