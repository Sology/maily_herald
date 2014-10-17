module MailyHerald
  class Log < ActiveRecord::Base
    AVAILABLE_STATUSES = [:scheduled, :delivered, :skipped, :error]

    belongs_to  :entity,        polymorphic: true
    belongs_to  :mailing,       class_name: "MailyHerald::Dispatch", foreign_key: :mailing_id

    validates   :entity,        presence: true
    validates   :mailing,       presence: true
    validates   :status,        presence: true, inclusion: {in: AVAILABLE_STATUSES}

    validates   :processing_at, presence: true, if: :scheduled?

    default_scope               lambda { order("processing_at asc") }
    scope       :for_entity,    lambda {|entity| where(entity_id: entity.id, entity_type: entity.class.base_class) }
    scope       :for_mailing,   lambda {|mailing| where(mailing_id: mailing.id) }
    scope       :for_mailings,  lambda {|mailings| where("mailing_id in (?)", mailings) }
    scope       :delivered,     lambda { where(status: :delivered) }
    scope       :skipped,       lambda { where(status: :skipped) }
    scope       :error,         lambda { where(status: :error) }
    scope       :scheduled,     lambda { where(status: :scheduled) }
    scope       :processed,     lambda { where(status: [:delivered, :skipped, :error]) }

    serialize   :data,          Hash

    if Rails::VERSION::MAJOR == 3
      attr_accessible :status, :data
    end

    def self.create_for mailing, entity, attributes = {}
      log = Log.new
      log.set_attributes_for mailing, entity, attributes
      log.save!
      log
    end

    def set_attributes_for mailing, entity, attributes = {}
      self.mailing = mailing
      self.entity = entity
      self.entity_email = mailing.destination(entity)

      self.processing_at = attributes[:processing_at] || DateTime.now
      self.status = attributes[:status]
      self.data = attributes[:data]
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
