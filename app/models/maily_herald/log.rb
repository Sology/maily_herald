module MailyHerald
  class Log < ActiveRecord::Base
    AVAILABLE_STATUSES = [:scheduled, :delivered, :skipped, :error]

    belongs_to  :entity,        :polymorphic => true
    belongs_to  :mailing,       :class_name => "MailyHerald::Mailing", :foreign_key => :mailing_id

    validates   :entity,        :presence => true
    validates   :mailing,       :presence => true
    validates   :status,        :presence => true, :inclusion => {:in => AVAILABLE_STATUSES}

    validates   :processing_at, :presence => true, :if => :scheduled?

    default_scope               order("processing_at asc")
    scope       :for_entity,    lambda {|entity| where(:entity_id => entity.id, :entity_type => entity.class.base_class) }
    scope       :for_mailing,   lambda {|mailing| where(:mailing_id => mailing.id) }
    scope       :for_mailings,  lambda {|mailings| where("mailing_id in (?)", mailings) }
    scope       :delivered,     where(:status => :delivered)
    scope       :skipped,       where(:status => :skipped)
    scope       :error,         where(:status => :error)
    scope       :scheduled,     where(:status => :scheduled)
    scope       :processed,     where(:status => [:delivered, :skipped, :error])

    serialize   :data,          Hash

    attr_accessible :status, :data

    def self.create_for mailing, entity, status = :delivered, data = nil
      log = Log.new
      log.mailing = mailing
      log.entity = entity
      log.processing_at = DateTime.now
      log.status = status
      log.data = data if data
      log.save!
      log
    end

    def status
      read_attribute(:status).to_sym
    end

    def delivered?
      self.status == :delivered
    end

    def skipped?
      self.status == :skipped
    end

    def error?
      self.status == :error
    end

    def scheduled?
      self.status == :scheduled
    end
  end
end
