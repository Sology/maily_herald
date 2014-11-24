require 'time'
require 'logger'

module MailyHerald
  module Logging
    OPTIONS = {
      target: STDOUT,
      level: Logger::INFO,
      progname: "app"
    }

    module LoggerExtensions
      def log_processing *args
        options = args.extract_options!
        mailing, entity, mail = nil
        args.each do |arg|
          case arg
          when Mailing
            mailing = arg
          when ::Mail::Message
            mail = arg
          else
            entity = arg
          end
        end
        prefix = options.delete(:prefix)
        level = options.delete(:level) || :info

        log_msg = []
        if entity.is_a?(Hash)
          log_msg << "<#{entity[:class]}##{entity[:id]}> #{mail.try(:to)}" if entity
        else
          log_msg << "<#{entity.try(:class).try(:name)}##{entity.try(:id)}> #{entity} #{mail.try(:to)}" if entity
        end
        log_msg << "<#{mailing.try(:class).try(:name)}##{mailing.try(:id)}> #{mailing}" if mailing

        send(level, [prefix, log_msg.join(", ")].compact.join(": "))
      end
    end

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
      @logger.extend(LoggerExtensions)

      oldlogger.close if oldlogger
      @logger
    end

    def self.initialized?
      !!@logger
    end

    def self.logger opts = {}
      @logger || initialize(opts)
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
