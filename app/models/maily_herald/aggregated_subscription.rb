module MailyHerald
  class AggregatedSubscription < ActiveRecord::Base
    belongs_to  :entity,              :polymorphic => true
    belongs_to  :group,               :class_name => "MailyHerald::SubscriptionGroup"

    has_many    :mailings,            :through => :group
    has_many    :sequences,           :through => :group

    scope       :for_entity,          lambda {|entity| where(:entity_id => entity.id, :entity_type => entity.class.base_class) }

    def deactivate!
      update_attribute(:active, false)
      save!
    end

    def activate!
      update_attribute(:active, true)
      save!
    end
  end
end
