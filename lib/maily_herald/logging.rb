require 'time'
require 'logger'

module MailyHerald
  module Logging
    OPTIONS = {
      target: STDOUT,
      level: Logger::INFO,
      progname: "app"
    }

    class Formatter < Logger::Formatter
      def call(severity, time, program_name, message)
        "#{time.utc.iso8601} #{Process.pid} [Maily##{"%3s" % program_name}] #{severity}: #{message}\n"
      end
    end

    def self.initialize(opts = {})
      oldlogger = @logger

      @options ||= OPTIONS.dup
      @options.merge!(opts) if opts

      @logger = Logger.new(@options[:target])
      @logger.level = @options[:level]
      @logger.formatter = Formatter.new
      @logger.progname = @options[:progname]

      oldlogger.close if oldlogger
      @logger
    end

    def self.logger
      @logger || initialize
    end

    def self.logger=(log)
      @logger = (log ? log : Logger.new('/dev/null'))
    end

    def self.options
      @options || OPTIONS.dup
    end

    def self.safe_options
      opts = self.options.dup
      opts[:target] = nil if !opts[:target].is_a?(String)
      opts
    end

    def logger
      MailyHerald::Logging.logger
    end
  end
end
