# frozen_string_literal: true

require "thor"
require "colorize"
require "httparty"
require "pry"

module XxxRename
  class Error < StandardError; end

  class SearchError < Error
    attr_reader :entity, :request_options, :response_code, :response_body

    def initialize(entity, object)
      @entity = entity
      @request_options = object[:request_options]
      @response_code = object[:response_code]
      @response_body = object[:response_body]
      super("Network Error while fetching details for file #{@entity}")
    end

    def dump_error
      File.open(File.join($pwd, "error_dump.txt"), "a") do |dump|
        dump << "--------ERROR BEGIN--------\n#{message}\n"
        dump << "--------ENTITY--------\n#{@entity}\n"
        dump << "--------REQUEST--------\n#{@request_options}\n"
        dump << "--------CODE--------\n#{@response_code}\n"
        dump << "--------BODY--------\n#{@response_body}\n"
        dump << "--------ERROR END--------\n\n\n"
      end
    end
  end

  class TooManyRequestsError < Error
    def initialize(endpoint)
      super("FATAL: Too many requests made to #{endpoint}. Please try after some time")
    end
  end
end

# Helper files
require_relative "xxx_rename/cli"
require_relative "xxx_rename/network_helper"
require_relative "xxx_rename/output"
require_relative "xxx_rename/utils"
require_relative "xxx_rename/validator"

# Commands
require_relative "xxx_rename/rollback"
require_relative "xxx_rename/search_by_filename"
require_relative "xxx_rename/search_by_performer"
require_relative "xxx_rename/version"

# Helper for Rename by files command
require_relative "xxx_rename/scene_by_file/base"
require_relative "xxx_rename/scene_by_file/brazzers"
require_relative "xxx_rename/scene_by_file/digital_playground"

# Helper for Rename by performer command
require_relative "xxx_rename/scene_by_performer/base"
require_relative "xxx_rename/scene_by_performer/brazzers"
require_relative "xxx_rename/scene_by_performer/digital_playground"
