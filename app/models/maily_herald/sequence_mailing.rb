module MailyHerald
  class SequenceMailing < Mailing
    attr_accessible :absolute_delay_in_days

    belongs_to  :sequence,      class_name: "MailyHerald::Sequence"

    validates   :absolute_delay,presence: true, numericality: true

    delegate    :subscription,  to: :sequence
    delegate    :list,          to: :sequence

    after_update if: Proc.new{|m| m.absolute_delay_changed?} do
      self.sequence.update_schedules
    end

    def absolute_delay_in_days
      "%.2f" % (self.absolute_delay.to_f / 1.day.seconds)
    end
    def absolute_delay_in_days= d
      self.absolute_delay = d.to_f.days
    end

    def processed_to? entity
      self.sequence.processed_mailings_for(entity).include?(self)
    end

    def deliver_to entity
      super(entity)
    end

    def deliver_with_mailer_to entity
      current_time = Time.now
      subscription = subscription_for entity
      return unless subscription && processable?(entity)

      schedule = self.sequence.schedule_for(entity)

      subscription.with_lock do
        if schedule.mailing == self && schedule.processing_at && schedule.processing_at <= current_time
          attrs = super entity
          if attrs
            schedule.attributes = attrs
            schedule.processing_at = current_time
            schedule.save!
            self.sequence.set_schedule_for(entity)
          end
        end
      end
    end

    def override_subscription?
      self.sequence.override_subscription? || super
    end
  end
end
