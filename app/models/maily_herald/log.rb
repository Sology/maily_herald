module MailyHerald
  class Log < ActiveRecord::Base
    AVAILABLE_STATUSES = [:delivered, :skipped, :error]

    belongs_to  :entity,        :polymorphic => true
    belongs_to  :mailing,       :class_name => "MailyHerald::Mailing", :foreign_key => :mailing_id

    validates   :entity,        :presence => true
    validates   :mailing,       :presence => true
    validates   :status,        :presence => true, :inclusion => {:in => AVAILABLE_STATUSES}

    default_scope               order("processed_at asc")
    scope       :for_entity,    lambda {|entity| where(:entity_id => entity.id, :entity_type => entity.class.base_class) }
    scope       :for_mailing,   lambda {|mailing| where(:mailing_id => mailing.id) }
    scope       :delivered,     where(:status => :delivered)
    scope       :skipped,       where(:status => :skipped)
    scope       :error,         where(:status => :error)

    serialize   :data,          Hash

    def self.create_for mailing, entity, status = :delivered, data = nil
      log = Log.new
      log.mailing = mailing
      log.entity = entity
      log.processed_at = DateTime.now
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
  end
end
