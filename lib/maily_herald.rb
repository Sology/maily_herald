require 'maily_herald/version'

require 'liquid'
require 'sidekiq'
require 'redis'

if defined?(::Rails::Engine)
  require "maily_herald/engine"
end

module MailyHerald
  class Async
    include Sidekiq::Worker

    def perform args = {}
      if args["logger"]
        logger_opts = {level: args["logger"]["level"], progname: "bkg"}
        logger_opts[:target] = args["logger"]["target"]
        MailyHerald::Logging.initialize(logger_opts)
      end

      if args["mailing"]
        MailyHerald::Manager.run_mailing args["mailing"]
      elsif args["sequence"]
        MailyHerald::Manager.run_sequence args["sequence"]
      else
        MailyHerald::Manager.run_all
      end
    end
  end

  class ScheduleUpdater
    include Sidekiq::Worker

    def perform id
      dispatch = MailyHerald::Dispatch.find(id)
      dispatch.set_schedules if dispatch.respond_to?(:set_schedules)
    end
  end

  class Initializer
    def initialize klass
      @klass = klass
    end

    def method_missing m, *args, &block
      if %w{list ad_hoc_mailing one_time_mailing periodical_mailing sequence_mailing sequence}.include?(m.to_s)
        options = args.extract_options!
        @klass.send m, *args, options.merge(locked: true), &block
      else
        @klass.send m, *args, &block
      end
    end
  end

  autoload :Utils,              'maily_herald/utils'
  autoload :TemplateRenderer,   'maily_herald/template_renderer'
  autoload :ModelExtensions,    'maily_herald/model_extensions'
  autoload :Context,            'maily_herald/context'
  autoload :Manager,            'maily_herald/manager'
	autoload :Autonaming,					'maily_herald/autonaming'
	autoload :Logging,					  'maily_herald/logging'

  @@token_redirect = nil

  class << self
    # Returns config options read from config file.
    def options
      @options ||= read_options
    end

    # Assign config options.
    def options=(opts)
      @options = opts
    end

    # Get list of locked dispatches.
    def locked_dispatches
      @@locked_dispatches ||= []
    end

    # Lock a dispatch.
    #
    # @param name [Symbol] Dispatch identifier name.
    def lock_dispatch name
      name = name.to_s
      self.locked_dispatches << name unless @@locked_dispatches.include?(name)
    end

    # Check if dispatch is locked.
    #
    # @param name [Symbol] Dispatch identifier name.
    def dispatch_locked? name
      self.locked_dispatches.include?(name.to_s)
    end

    # Get list of locked lists.
    def locked_lists
      @@locked_lists ||= []
    end

    # Lock a list.
    #
    # @param name [Symbol] List identifier name.
    def lock_list name
      name = name.to_s
      self.locked_lists << name unless @@locked_lists.include?(name)
    end

    # Check if List is locked.
    #
    # @param name [Symbol] List identifier name.
    def list_locked? name
      self.locked_lists.include?(name.to_s)
    end

    def start_at_procs
      @@start_at_procs ||= {}
    end

    def conditions_procs
      @@conditions_procs ||= {}
    end

    # Obtains Redis connection.
    def redis
      @redis ||= begin
                   client = Redis.new(
                     url: options[:redis_url] || 'redis://localhost:6379/0',
                     driver: options[:redis_driver] || "ruby"
                   )

                   if options[:redis_namespace]
                     require 'redis/namespace'
                     Redis::Namespace.new(options[:redis_namespace], redis: client)
                   else
                     client
                   end
                 end
    end

    # Gets the Maily logger.
    def logger
      unless MailyHerald::Logging.initialized?
        opts = {
          level: options[:verbose] ? Logger::DEBUG : Logger::INFO,
        }
        opts[:target] = options[:logfile] if options[:logfile]

        MailyHerald::Logging.initialize(opts)
      end
      MailyHerald::Logging.logger
    end

    # Performs Maily setup.
    #
    # To be used in initializer file.
    def setup
      logger.warn("Maily migrations seems to be pending. Skipping setup...") && return if ([MailyHerald::Dispatch, MailyHerald::List, MailyHerald::Log, MailyHerald::Subscription].collect(&:table_exists?).select{|v| !v}.length > 0)

      yield Initializer.new(self)
    end

    # Fetches or defines a {Context}.
    #
    # If no block provided, Context with given +name+ is returned.
    #
    # If block provided, Context with given +name+ is created and then block
    # is evaluated within that Context.
    #
    # @param name [Symbol] Identifier name of the Context.
    def context name, &block
      name = name.to_s
      @@contexts ||= {}

      if block_given?
        @@contexts ||= {}
        @@contexts[name] ||= MailyHerald::Context.new(name)
        yield @@contexts[name]
      else
        @@contexts[name]
      end
    end

    # Returns a dispatch with given identifier name.
    #
    # Dispatch is basically any object extending {MailyHerald::Dispatch}.
    #
    # @param name [Symbol] Dispatch identifier name.
    def dispatch name
      MailyHerald::Dispatch.find_by_name(name)
    end

    # Fetches or defines an {AdHocMailing}.
    #
    # If no block provided, {AdHocMailing} with given +name+ is returned.
    #
    # If block provided, {AdHocMailing} with given +name+ is created or edited 
    # and block is evaluated within that mailing.
    #
    # @option options [true, false] :locked (false) Determines whether Mailing is locked.
    # @see Dispatch#locked?
    def ad_hoc_mailing name, options = {}
      mailing = MailyHerald::AdHocMailing.where(name: name).first 
      lock = options.delete(:locked)

      if block_given? && !self.dispatch_locked?(name) && (!mailing || lock)
        mailing ||= MailyHerald::AdHocMailing.new(name: name)
        yield(mailing)
        mailing.save! 

        MailyHerald.lock_dispatch(name) if lock
      end

      mailing
    end

    # Fetches or defines an {OneTimeMailing}.
    #
    # If no block provided, {OneTimeMailing} with given +name+ is returned.
    #
    # If block provided, {OneTimeMailing} with given +name+ is created or edited 
    # and block is evaluated within that mailing.
    #
    # @option options [true, false] :locked (false) Determines whether Mailing is locked.
    # @see Dispatch#locked?
    def one_time_mailing name, options = {}
      mailing = MailyHerald::OneTimeMailing.where(name: name).first 
      lock = options.delete(:locked)

      if block_given? && !self.dispatch_locked?(name) && (!mailing || lock)
        mailing ||= MailyHerald::OneTimeMailing.new(name: name)
        yield(mailing)
        mailing.save! 

        MailyHerald.lock_dispatch(name) if lock
      end

      mailing
    end

    # Fetches or defines an {PeriodicalMailing}.
    #
    # If no block provided, {PeriodicalMailing} with given +name+ is returned.
    #
    # If block provided, {PeriodicalMailing} with given +name+ is created or edited 
    # and block is evaluated within that mailing.
    #
    # @option options [true, false] :locked (false) Determines whether Mailing is locked.
    # @see Dispatch#locked?
    def periodical_mailing name, options = {}
      mailing = MailyHerald::PeriodicalMailing.where(name: name).first 
      lock = options.delete(:locked)

      if block_given? && !self.dispatch_locked?(name) && (!mailing || lock)
        mailing ||= MailyHerald::PeriodicalMailing.new(name: name)
        yield(mailing)
        mailing.save!

        self.lock_dispatch(name) if lock
      end

      mailing
    end

    # Fetches or defines an {Sequence}.
    #
    # If no block provided, {Sequence} with given +name+ is returned.
    #
    # If block provided, {Sequence} with given +name+ is created or edited 
    # and block is evaluated within that mailing.
    # Additionally, within provided block, using {Sequence#mailing} method, 
    # {SequenceMailing sequence mailings} can be defined.
    #
    # @option options [true, false] :locked (false) Determines whether Mailing is locked.
    # @see Dispatch#locked?
    # @see Sequence#mailing
    def sequence name, options = {}
      sequence = MailyHerald::Sequence.where(name: name).first 
      lock = options.delete(:locked)

      if block_given? && !self.dispatch_locked?(name) && (!sequence || lock)
        sequence ||= MailyHerald::Sequence.new(name: name)
        yield(sequence)
        sequence.save!

        self.lock_dispatch(name) if lock
      end

      sequence
    end

    # Fetches or defines a {List}.
    #
    # If no block provided, {List} with given +name+ is returned.
    #
    # If block provided, {List} with given +name+ is created or edited 
    # and block is evaluated within that list.
    #
    # @option options [true, false] :locked (false) Determines whether {List} is locked.
    # @see List#locked?
    def list name, options = {}
      list = MailyHerald::List.where(name: name).first 
      lock = options.delete(:locked)

      if block_given? && !self.list_locked?(name) && (!list || lock)
        list ||= MailyHerald::List.new(name: name)
        yield(list)
        list.save!

        self.lock_list(name) if lock
      end

      list
    end

    # Subscribe +entity+ to {List lists} identified by +list_names+.
    #
    # @see List#subscribe!
    def subscribe entity, *list_names
      list_names.each do |ln| 
        list = MailyHerald.list(ln)
        next unless list

        list.subscribe! entity
      end
    end

    # Unsubscribe +entity+ from {List lists} identified by +list_names+.
    #
    # @see List#unsubscribe!
    def unsubscribe entity, *list_names
      list_names.each do |ln| 
        list = MailyHerald.list(ln)
        next unless list

        list.unsubscribe! entity
      end
    end

    # Return all defined {Context Contexts}.
    def contexts
      @@contexts ||= {}
    end

    def token_redirect &block
      if block_given?
        @@token_redirect = block
      else
        @@token_redirect
      end
    end

    def run_sequence seq_name
      seq_name = seq_name.name if seq_name.is_a?(Sequence)

      Async.perform_async sequence: seq_name, logger: MailyHerald::Logging.safe_options
    end

    def run_mailing mailing_name
      mailing_name = mailing_name.name if mailing_name.is_a?(Mailing)

      Async.perform_async mailing: mailing_name, logger: MailyHerald::Logging.safe_options
    end

    def run_all
      Async.perform_async(logger: MailyHerald::Logging.safe_options)
    end

    def find_subscription_for mailer_name, mailing_name, entity
      mailing = MailyHerald::Mailing.where(mailer_name: mailer_name, name: mailing_name).first
      mailing.subscription_for entity
    end

    # Read options from config file
    def read_options cfile = "config/maily_herald.yml"
      opts = {}
      if File.exist?(cfile)
        opts = YAML.load(ERB.new(IO.read(cfile)).result)
      end
      opts
    end
  end
end
