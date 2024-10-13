# frozen_string_literal: true

require "logger"

module XxxRename
  class CustomLogger < Logger
    EXTRA = Logger::DEBUG - 2
    TRACE = Logger::DEBUG - 1

    SEV_LABEL = {
      -2 => "EXTRA",
      -1 => "TRACE",
      0 => "DEBUG",
      1 => "INFO",
      2 => "WARN",
      3 => "ERROR",
      4 => "FATAL"
    }.freeze

    def format_severity(severity)
      SEV_LABEL[severity] || "ANY"
    end

    def trace(message)
      add(TRACE, message)
    end

    def extra(message)
      add(EXTRA, message)
    end
  end

  class Log
    attr_accessor :logger

    CLI_LOGGING = "CLI"
    STASHAPP_LOGGING = "STASHAPP"

    def initialize(mode, level)
      case mode
      when CLI_LOGGING      then cli_logger(level)
      when STASHAPP_LOGGING then stashapp_logger
      else                  raise Errors::FatalError, "xxx_rename initialised with invalid mode #{mode}"
      end
    end

    private

    def cli_logger(level)
      @logger = CustomLogger.new($stdout)
      @logger.level = case level.upcase
                      when "EXTRA" then CustomLogger::EXTRA
                      when "TRACE" then CustomLogger::TRACE
                      when "DEBUG" then CustomLogger::DEBUG
                      when "INFO"  then CustomLogger::INFO
                      when "WARN"  then CustomLogger::WARN
                      when "ERROR" then CustomLogger::ERROR
                      when "FATAL" then CustomLogger::FATAL
                      else raise "Invalid log level #{level}"
                      end
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime("%H:%M:%S")
        case severity
        when "FATAL" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:red)} #{msg}\n"
        when "ERROR" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:light_red)} #{msg}\n"
        when "WARN"  then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:yellow)} #{msg}\n"
        when "INFO"  then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:magenta)} #{msg}\n"
        when "DEBUG" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:light_magenta)} #{msg}\n"
        when "TRACE" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:cyan)} #{msg}\n"
        when "EXTRA" then "#{"[#{date_format}] [#{severity.ljust(5)}]".to_s.colorize(:light_cyan)} #{msg}\n"
        else "[#{date_format}] [#{severity.ljust(5)}] #{msg}\n"
        end
      end
    end

    def stashapp_logger
      @logger = CustomLogger.new($stderr)
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
