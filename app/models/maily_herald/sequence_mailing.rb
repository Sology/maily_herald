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

    def processed_to? entity
      self.sequence.processed_mailings_for(entity).include?(self)
    end

    def deliver_to entity
      current_time = Time.now
      subscription = subscription_for entity
      return unless subscription.processable?

      subscription.with_lock do
        if subscription.next_mailing == self && subscription.processing_time_for(self) && subscription.processing_time_for(self) <= current_time
          super entity
        end
      end
    end
  end
end
