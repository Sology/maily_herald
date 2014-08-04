module MailyHerald
  class Dispatch < ActiveRecord::Base
    belongs_to  :list,          :class_name => "MailyHerald::List"

    validates   :name,          :presence => true, :format => {:with => /^\w+$/}, :uniqueness => true
    validates   :list,          :presence => true

    delegate :subscription_for, :to => :list

    def list= l
      l = MailyHerald::List.find_by_name(l.to_s) if l.is_a?(String) || l.is_a?(Symbol)
      super(l)
    end

    def processable? entity
      self.enabled? && (self.override_subscription? || self.list.subscribed?(entity))
    end

  end
end
