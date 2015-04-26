module MailyHerald
  class AdHocMailing < Mailing
    validates   :list,          presence: true

    # Sends mailing to all subscribed entities.
    #
    # Performs actual sending of emails; should be called in background.
    #
    # Returns array of `Mail::Message`.
    def run
      self.list.subscriptions.collect do |subscription|
        entity = subscription.entity

        next unless processable?(entity)

        deliver_to entity
      end
    end

    # Returns single `Mail::Message`.
    def deliver_with_mailer_to entity
      attrs = super entity
      Log.create_for(self, entity, attrs) if attrs
    end

    def to_s
      "<AdHocMailing: #{self.title || self.name}>"
    end
  end
end
