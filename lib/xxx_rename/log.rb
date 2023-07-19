# frozen_string_literal: true

require "logger"

module XxxRename
  class Log
    attr_accessor :logger

    CLI_LOGGING = "CLI"
    STASHAPP_LOGGING = "STASHAPP"

    def initialize(mode, verbose)
      case mode
      when CLI_LOGGING      then cli_logger(verbose)
      when STASHAPP_LOGGING then stashapp_logger
      else                  raise Errors::FatalError, "xxx_rename initialised with invalid mode #{mode}"
      end
    end

    private

    def cli_logger(verbose)
      @logger = Logger.new($stdout)
      @logger.level = verbose ? "DEBUG" : "INFO"
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime("%H:%M:%S")
        case severity
        when "INFO"  then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:blue)} #{msg}\n"
        when "ERROR" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:light_red)} #{msg}\n"
        when "FATAL" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:red)} #{msg}\n"
        when "WARN"  then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:yellow)} #{msg}\n"
        when "DEBUG" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:light_magenta)} #{msg}\n"
        else "[#{date_format}] [#{severity.ljust(5)}] #{msg}\n"
        end
      end
    end

    def stashapp_logger
      @logger = Logger.new($stderr)
      @logger.formatter = proc do |severity, _datetime, _progname, msg|
        case severity
        when "DEBUG" then make_log_text("d", msg)
        when "INFO"  then make_log_text("i", msg)
        when "WARN"  then make_log_text("w", msg)
        when "ERROR" then make_log_text("e", msg)
        when "FATAL" then make_log_text("e", msg)
        else make_log_text("i", msg)
        end
      end
      String.disable_colorization true
    end

    def make_log_text(level, msg)
      # Wraps the string between the SOH and STX control characters
      level_char = "\x01#{level}\x02"
      text = msg.inspect.gsub(/data:image.+?;base64(.+?')/) { |_match| text }
      "#{text.split("\n").map { |message| level_char + message }.join("\n")}\n"
    end
  end
end
