module MailyHerald
  class PeriodicalMailing < Mailing
    attr_accessible :start, :start_var, :period

    validates   :context_name,  :presence => true

    def context
      @context ||= MailyHerald.context self.context_name
    end

    def subscription_for entity
      subscription = self.subscriptions.for_entity(entity).first
      unless subscription 
        if self.autosubscribe && context.scope.include?(entity)
          subscription = self.subscriptions.build
          subscription.entity = entity
          subscription.save
        else
          subscription = self.subscriptions.build
          subscription.entity = entity
        end
      end
      subscription
    end

    def deliver_to entity
      subscription = subscription_for entity
      return unless subscription.deliverable?

      if self.mailer_name == 'generic'
        # TODO make it atomic
        Mailer.generic(self, entity).deliver

        DeliveryLog.create_for self, entity
      else
        # TODO
      end
    end

    def run
      current_time = Time.now
      self.context.scope.each do |entity|
        subscription = subscription_for entity
        next unless subscription.deliverable?

        if !subscription.last_delivery_time || (subscription.last_delivery_time <= current_time - self.period)
          deliver_to entity
        end
      end
    end
  end
end
