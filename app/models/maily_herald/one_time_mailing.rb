module MailyHerald
  class OneTimeMailing < Mailing
    validates   :context_name,  :presence => true

    def context
      @context ||= MailyHerald.context self.context_name
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
