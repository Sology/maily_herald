module MailyHerald
  class AggregatedSubscription < ActiveRecord::Base
    belongs_to  :entity,              :polymorphic => true
    belongs_to  :group,               :class_name => "MailyHerald::SubscriptionGroup"

    has_many    :mailings,            :through => :group
    has_many    :sequences,           :through => :group

    scope       :for_entity,          lambda {|entity| where(:entity_id => entity.id, :entity_type => entity.class.base_class) }
  end
end
