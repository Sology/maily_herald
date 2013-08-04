module MailyHerald
  class DeliveryLog < ActiveRecord::Base
    belongs_to  :entity,        :polymorphic => true
    belongs_to  :mailing,       :class_name => "MailyHerald::Mailing"

    validates   :entity,        :presence => true
    validates   :mailing,       :presence => true

    scope       :for_entity,    lambda {|entity| where(:entity_id => entity.id, :entity_type => entity.class.base_class) }
    scope       :for_mailing,   lambda {|mailing| where(:mailing_id => mailing.id) }

    default_scope               order("delivered_at asc")

    def self.create_for mailing, entity
      log = DeliveryLog.new
      log.mailing = mailing
      log.entity = entity
      log.delivered_at = DateTime.now
      log.save
      log
    end
  end
end
