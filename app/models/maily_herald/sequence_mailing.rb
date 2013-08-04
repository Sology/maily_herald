module MailyHerald
  class SequenceMailing < Mailing
    belongs_to  :sequence,      :class_name => "MailyHerald::Sequence"

    acts_as_list :scope => :sequence

    def context
      @context ||= MailyHerald.context sequence.context_name
    end

    def subscription_for entity
      self.sequence.subscription_for entity
    end

    def deliver_to entity
      subscription = subscription_for entity
      return unless subscription.deliverable?
      return unless evaluate_conditions_for(entity)

      if self.mailer_name == 'generic'
        # TODO make it atomic
        Mailer.generic(self.destination_for(entity), prepare_for(entity)).deliver

        DeliveryLog.create_for self, entity
      else
        # TODO
      end
    end

    def delivered_to? entity
      self.sequence.delivered_mailings_for(entity).include?(self)
    end
  end
end
