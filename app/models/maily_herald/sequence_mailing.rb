module MailyHerald
  class SequenceMailing < Mailing
    attr_accessible :absolute_delay_in_days

    belongs_to  :sequence,      :class_name => "MailyHerald::Sequence"

    validates   :absolute_delay,      :presence => true, :numericality => true

    def absolute_delay_in_days
      "%.2f" % (self.absolute_delay.to_f / 1.day.seconds)
    end
    def absolute_delay_in_days= d
      self.absolute_delay = d.to_f.days
    end

    def context
      @context ||= MailyHerald.context sequence.context_name
    end
    def context=
      nil
    end

    def subscription_for entity
      self.sequence.subscription_for entity
    end

    def deliver_to entity
      subscription = subscription_for entity
      return unless subscription.processable?
      unless subscription.conditions_met?(self)
        Log.create_for self, entity, :skipped
        return
      end

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

    def processed_to? entity
      self.sequence.processed_mailings_for(entity).include?(self)
    end
  end
end
