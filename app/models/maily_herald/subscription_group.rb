module MailyHerald
  class SubscriptionGroup < ActiveRecord::Base
    attr_accessible :name, :title

    has_many        :mailings
    has_many        :sequences
    has_many        :aggregated_subscriptions, :foreign_key => "group_id"

    validates       :name,                :presence => true, :format => {:with => /^\w+$/}, :uniqueness => true
    validates       :title,               :presence => true

    before_validation do
      write_attribute(:name, self.title.downcase.gsub(/\W/, "_")) if self.title && (!self.name || self.name.empty?)
    end

    def to_s
      self.title
    end
  end
end
