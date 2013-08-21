module MailyHerald
  class SequenceMailing < Mailing
    attr_accessible :relative_delay_in_days

    belongs_to  :sequence,      :class_name => "MailyHerald::Sequence"

    validates   :relative_delay,      :presence => true, :numericality => true

    acts_as_list :scope => :sequence

    def relative_delay_in_days
      "%.2f" % (self.relative_delay.to_f / 1.day.seconds)
    end
    def relative_delay_in_days= d
      self.relative_delay = d.to_f.days
    end

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
        Mailer.generic(self, entity, subscription).deliver

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
