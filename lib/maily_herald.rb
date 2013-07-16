require "maily_herald/engine"

module MailyHerald
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

  def self.deliver mailing, entity
    mailing = Mailing.find_by_name(mailing) if !mailing.is_a?(Mailing)

    if mailing
      worker = Worker.new mailing
      worker.deliver_to entity
    end
  end
end

require 'liquid'
