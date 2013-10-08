module MailyHerald
  class Dispatch < ActiveRecord::Base
    validates   :name,          :presence => true, :format => {:with => /^\w+$/}, :uniqueness => true

    def subscription_for entity
      subscription = self.subscriptions.for_entity(entity).first
      unless subscription 
        subscription = self.subscriptions.build
        subscription.entity = entity
        if self.autosubscribe && self.context.scope.include?(entity)
          if entity.respond_to?(:maily_herald_autosubscribe)
            subscription.active = entity.maily_herald_autosubscribe(self)
          else
            subscription.active = true
          end
        end
        subscription.save!
      end
      subscription
    end

  end
end
