module MailyHerald
  class SequenceMailing < Mailing
    if Rails::VERSION::MAJOR == 3
      attr_accessible :absolute_delay_in_days
    end

    attr_accessor :skip_updating_schedules

    belongs_to  :sequence,      class_name: "MailyHerald::Sequence"

    validates   :absolute_delay,presence: true, numericality: true
    validates   :sequence,      presence: true
    validate do
      self.errors.add(:list_id, :invalid) if self.list_id != self.sequence.try(:list_id)
    end

    delegate    :subscription,  to: :sequence
    delegate    :list,          to: :sequence

    before_validation do
      self.list_id = self.sequence.list_id
    end

    after_save :update_schedules_callback, if: Proc.new{|m| !m.skip_updating_schedules && (m.state_changed? || m.absolute_delay_changed?)} 

    def absolute_delay_in_days
      "%.2f" % (self.absolute_delay.to_f / 1.day.seconds)
    end
    def absolute_delay_in_days= d
      self.absolute_delay = d.to_f.days
    end

    # Checks if mailing has been sent to given entity.
    def processed_to? entity
      self.sequence.processed_mailings_for(entity).include?(self)
    end

    # Delivers mailing to given entity.
    def deliver_to entity
      super(entity)
    end

    def update_schedules_callback
      self.sequence.update_schedules_callback
    end

    # Returns collection of all delivery schedules ({Log} collection).
    def schedules
      self.sequence.schedules
    end

    def deliver_with_mailer_to entity
      current_time = Time.now

      schedule = self.sequence.schedule_for(entity)

      schedule.with_lock do
        # make sure schedule hasn't been processed in the meantime
        if schedule && schedule.mailing == self && schedule.processing_at && schedule.processing_at <= current_time && schedule.scheduled?

          attrs = super entity
          if attrs
            schedule.attributes = attrs
            schedule.processing_at = current_time
            schedule.save!
            self.sequence.set_schedule_for(entity)
          end
        end
      end if schedule
    end

    def override_subscription?
      self.sequence.override_subscription? || super
    end

    def processable? entity
      self.sequence.enabled? && super
    end
  end
end
