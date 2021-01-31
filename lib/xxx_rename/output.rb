# frozen_string_literal: true

require "csv"

module XxxRename
  class Output
    def add(path, old_file_name, new_file_name, success)
      response_ar << [path, old_file_name, new_file_name, success]
    end

    def write
      filename = "response_#{Time.now.strftime("%Y%m%d_%H%M")}.csv"
      CSV.open(filename, "w") do |csv|
        csv << headers
        response_ar.each do |ar|
          csv << ar
        end
      end
      filename
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
