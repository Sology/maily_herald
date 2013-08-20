module MailyHerald
  class SubscriptionGroup < ActiveRecord::Base
    attr_accessible :name

    has_many        :mailings
    has_many        :sequences
    has_many        :aggregated_subscriptions, :foreign_key => "group_id"

    validates       :title,       :presence => true
  end
end
