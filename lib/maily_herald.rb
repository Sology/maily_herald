require "maily_herald/logging"

require 'liquid'
require 'sidekiq'
require 'redis'

if defined?(::Rails::Engine)
  require "maily_herald/engine"
end

module MailyHerald
  TIME_FORMAT = "%Y-%m-%d %H:%M"

  DEFAULTS = {
    :environment => nil,
  }

  class Async
    include Sidekiq::Worker

    def perform args = {}
      if args["logger"]
        logger_opts = {:level => args["logger"]["level"], :progname => "bkg"}
        logger_opts[:target] = args["logger"]["target"]
        MailyHerald::Logging.initialize(logger_opts)
      end

      if args["mailing"] && args["entity"]
        MailyHerald::Manager.deliver args["mailing"], args["entity"]
      elsif args["mailing"]
        MailyHerald::Manager.run_mailing args["mailing"]
      elsif args["sequence"]
        MailyHerald::Manager.run_sequence args["sequence"]
      elsif args["simulate"]
        MailyHerald::Manager.simulate args["simulate"]
      else
        MailyHerald::Manager.run_all
      end
    end

  end

  autoload :Utils,              'maily_herald/utils'
  autoload :ConditionEvaluator, 'maily_herald/condition_evaluator'
  autoload :TemplateRenderer,   'maily_herald/template_renderer'
  autoload :ModelExtensions,    'maily_herald/model_extensions'
  autoload :Context,            'maily_herald/context'
  autoload :Manager,            'maily_herald/manager'
	autoload :Config,							'maily_herald/config'

  mattr_reader :default_from

  def self.options
    @options ||= DEFAULTS.dup
  end

  def self.options=(opts)
    @options = opts
  end

  def self.redis
    @redis ||= begin
                 client = Redis.new(
                   :url => options[:redis_url] || 'redis://localhost:6379/0',
                   :driver => options[:redis_driver] || "ruby"
                 )

                 if options[:redis_namespace]
                   require 'redis/namespace'
                   Redis::Namespace.new(options[:redis_namespace], :redis => client)
                 else
                   client
                 end
               end
  end

  def self.logger
    MailyHerald::Logging.logger
  end

  def self.setup
    @@contexts ||= {}
    @@token_custom_actions ||= {}

    logger.warn("Maily migrations seems to be pending. Skipping setup...") && return if ([Dispatch, List, Log, Subscription].collect(&:table_exists?).select{|v| !v}.length > 0)

    yield self

    Rails.application.config.to_prepare do
      @@contexts.each do|n, c|
        if c.model
          unless c.model.included_modules.include?(MailyHerald::ModelExtensions::AssociationsPatch)
            c.model.send(:include, MailyHerald::ModelExtensions::AssociationsPatch)
          end
        end
      end
    end
  end

  def self.context name, &block
    name = name.to_s

    if block_given?
      @@contexts ||= {}
      @@contexts[name] ||= MailyHerald::Context.new(name)
      yield @@contexts[name]
    else
      @@contexts[name]
    end
  end

  def self.dispatch name
    Dispatch.find_by_name(name)
  end

  def self.one_time_mailing name
    mailing = OneTimeMailing.find_or_initialize_by_name(name)
    if block_given? 
      yield(mailing)
      mailing.save! if mailing.new_record?
    end
    mailing
  end

  def self.periodical_mailing name
    mailing = PeriodicalMailing.find_or_initialize_by_name(name)
    if block_given? 
      yield(mailing)
      mailing.save! if mailing.new_record?
    end
    mailing
  end

  def self.sequence name
    sequence = Sequence.find_or_initialize_by_name(name)
    if block_given? 
      yield(sequence)
      sequence.save! if sequence.new_record?
    end
    sequence
  end

  def self.list name
    list = List.find_or_initialize_by_name(name)
    if block_given? 
      yield(list)
      list.save! if list.new_record?
    end
    list
  end

  def self.contexts
    @@contexts
  end

  def self.default_from= from
    @@default_from = from
  end

  def self.token_redirect &block
    if block_given?
      @@token_redirect = block
    else
      @@token_redirect
    end
  end

  def self.token_custom_action type, id, &block
    if block_given?
      @@token_custom_actions[type] ||= {}
      @@token_custom_actions[type][id] = block
    else
      @@token_custom_actions[type] ||= {}
      @@token_custom_actions[type][id]
    end
  end

  def self.deliver mailing_name, entity_id
    mailing_name = mailing_name.name if mailing_name.is_a?(Mailing)
    entity_id = entity_id.id if !entity_id.is_a?(Fixnum)

    Async.perform_async :mailing => mailing_name, :entity => entity_id, :logger => MailyHerald::Logging.safe_options
  end

  def self.run_sequence seq_name
    seq_name = seq_name.name if seq_name.is_a?(Sequence)

    Async.perform_async :sequence => seq_name, :logger => MailyHerald::Logging.safe_options
  end

  def self.run_mailing mailing_name
    mailing_name = mailing_name.name if mailing_name.is_a?(Mailing)

    Async.perform_async :mailing => mailing_name, :logger => MailyHerald::Logging.safe_options
  end

  def self.run_all
    Async.perform_async(:logger => MailyHerald::Logging.safe_options)
  end

  def self.simulate period = 1.year
    Async.perform_async :simulate => period, :logger => MailyHerald::Logging.safe_options
  end

  def self.simulation_ongoing?
    File.exist?("/tmp/maily_herlald_timetravel.lock")
  end

  def self.find_subscription_for mailer_name, mailing_name, entity
    mailing = MailyHerald::Mailing.where(:mailer_name => mailer_name, :name => mailing_name).first
    mailing.subscription_for entity
  end
end
