module MailyHerald
  class OneTimeMailing < Mailing
    validates   :context_name,  :presence => true

    def context
      @context ||= MailyHerald.context self.context_name
    end

    def subscription_for entity
      subscription = self.subscriptions.for_entity(entity).first
      unless subscription 
        subscription = self.subscriptions.build
        subscription.entity = entity
        if self.autosubscribe && context.scope.include?(entity)
          subscription.active = true
          subscription.save!
        end
      end
      subscription
    end

    def deliver_to entity
      subscription = subscription_for entity
      return unless subscription.processable?

      if self.mailer_name == 'generic'
        # TODO make it atomic
        mail = Mailer.generic(self, entity, subscription)
        mail.deliver
        Log.create_for self, entity, :delivered, {:content => mail.to_s}
      else
        # TODO
      end
    rescue StandardError => e
      Log.create_for self, entity, :error, {:msg => e.to_s}
    end

    def run
      current_time = Time.now
      self.context.scope.each do |entity|
        subscription = subscription_for entity
        next unless subscription.processable?

        deliver_to entity
      end
    end
  end
end
