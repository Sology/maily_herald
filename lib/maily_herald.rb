require 'sidekiq'
require "maily_herald/engine"

module MailyHerald
  class Async
    include Sidekiq::Worker

    def perform args
      if args["entity"]
        MailyHerald::Manager.deliver args["mailing"], args["entity"]
      else
        MailyHerald::Manager.deliver_all args["mailing"]
      end
    end

  end

  autoload :Utils,            'maily_herald/utils'
  autoload :ModelExtensions,  'maily_herald/model_extensions'
  autoload :Context,          'maily_herald/context'
  autoload :Worker,           'maily_herald/worker'
  autoload :Manager,          'maily_herald/manager'

  mattr_reader :default_from

  def self.setup
    yield self
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

  def self.mailing name
    if Mailing.table_exists?
      mailing = Mailing.find_or_initialize_by_name(name)
      if block_given?
        yield(mailing)
        mailing.save
      end
      mailing
    end
  end

  def self.contexts
    @@contexts
  end

  def self.default_from= from
    @@default_from = from
  end

  def self.deliver mailing_name, entity_id
    mailing_name = mailing_name.name if mailing_name.is_a?(Mailing)
    entity_id = entity_id.id if !entity_id.is_a?(Fixnum)

    Async.perform_async :mailing => mailing_name, :entity => entity_id
  end

  def self.deliver_all mailing_name
    mailing_name = mailing_name.name if mailing_name.is_a?(Mailing)

    Async.perform_async :mailing => mailing_name
  end
end

require 'liquid'
