# frozen_string_literal: true

require "xxx_rename/utils"
require "httparty"

module XxxRename
  module Integrations
    class Base
      include Utils
      include HTTParty

      attr_reader :config

      def initialize(config)
        @config = config
        self.class.logger(XxxRename.logger, :debug)
      end
    end
  end
end
