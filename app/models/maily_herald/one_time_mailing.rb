module MailyHerald
  class OneTimeMailing < Mailing
    validates   :list,          presence: true

    # Returns array of Mail::Message
    def run
      self.list.subscriptions.collect do |subscription|
        entity = subscription.entity

        next unless processable?(entity)

        deliver_to entity
      end
    end

    # Returns single Mail::Message
    def deliver_with_mailer_to entity
      subscription = self.list.subscription_for entity
      return unless subscription

      subscription.with_lock do
        attrs = super entity
        if attrs
          log = Log.new
          log.mailing = self
          log.entity = entity
          log.processing_at = Time.now
          log.attributes = attrs
          log.save!
        end
      end
    end
  end
end
