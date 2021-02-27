# frozen_string_literal: true

require "csv"

module XxxRename
  class Output
    def initialize(output)
      if output.nil? || output.empty?
        # Create a new file
        @filename = "response_#{Time.now.strftime("%Y%m%d_%H%M")}.csv"
        # Insert csv headers
        CSV.open(@filename, "w") do |csv|
          csv << headers
        end
      else
        raise "Output file #{output} is invalid. Check the path of the file." unless File.exist?(output)

        @filename = output
      end

    end

    def add(path, old_file_name, new_file_name, success)
      response_ar << [path, old_file_name, new_file_name, success]
    end

    def write
      CSV.open(@filename, "a") do |csv|
        response_ar.each do |ar|
          csv << ar
        end
      end
      @filename
    end

    def empty?
      response_ar.empty?
    end

    private

    def headers
      %w[path old_file_name new_file_name success]
    end

    def response_ar
      @response_ar ||= []
    end
  end
end
