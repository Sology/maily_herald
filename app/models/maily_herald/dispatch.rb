module MailyHerald
  class Dispatch < ActiveRecord::Base
    validates   :name,          :presence => true, :format => {:with => /^\w+$/}, :uniqueness => true

    def subscription_for entity
      subscription = self.subscriptions.for_entity(entity).first
      unless subscription 
        subscription = self.subscriptions.build
        subscription.entity = entity
        subscription.active = self.autosubscribe && self.context.scope.include?(entity)
        subscription.save!
      end
      subscription
    end

  end
end
