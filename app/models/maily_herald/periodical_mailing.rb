module MailyHerald
  class PeriodicalMailing < Mailing
    validates   :list,          presence: true
    validates   :start_at,      presence: true
    validates   :period,        presence: true, numericality: {greater_than: 0}

    after_save :update_schedules_callback, if: Proc.new{|m| m.saved_change_to_attribute?(:state) || m.saved_change_to_attribute?(:period) || m.saved_change_to_attribute?(:start_at) || m.override_subscription?}

    def period_in_days
      "%.2f" % (self.period.to_f / 1.day.seconds)
    end
    def period_in_days= d
      self.period = d.to_f.days
    end

    # Sends mailing to all subscribed entities.
    #
    # Performs actual sending of emails; should be called in background.
    #
    # Returns array of {MailyHerald::Log} with actual `Mail::Message` objects stored
    # in {MailyHerald::Log.mail} attributes.
    def run
      # TODO better scope here to exclude schedules for users outside context scope
      schedules.where("processing_at <= (?)", Time.now).collect do |schedule|
        if schedule.entity
          mail = deliver schedule
          schedule.reload
          schedule.mail = mail
          schedule
        else
          MailyHerald.logger.log_processing(schedule.mailing, {class: schedule.entity_type, id: schedule.entity_id}, prefix: "Removing schedule for non-existing entity") 
          schedule.destroy
        end
      end
    end

    # Sets delivery schedules of all entities in mailing scope.
    #
    # New schedules will be created or existing ones updated.
    def set_schedules
      self.list.context.scope_with_subscription(self.list, :outer).each do |entity|
        MailyHerald.logger.debug "Updating schedule of #{self} periodical for entity ##{entity.id} #{entity}"
        scheduler_for(entity).set_schedule
      end
    end

    def update_schedules_callback
      Rails.env.test? ? set_schedules : MailyHerald::ScheduleUpdater.perform_in(10.seconds, self.id)
    end

    # Returns collection of all delivery schedules ({Log} collection).
    def schedules
      Log.ordered.scheduled.for_mailing(self)
    end

    def to_s
      "<PeriodicalMailing: #{self.title || self.name}>"
    end

    def scheduler_for entity
      PeriodicalMailing::Scheduler.new self, entity
    end

    private

    def deliver_with_mailer schedule
      current_time = Time.now

      schedule.with_lock do
        # make sure schedule hasn't been processed in the meantime
        if schedule && schedule.processing_at <= current_time && schedule.scheduled?
          schedule = super(schedule)
          if schedule
            schedule.processing_at = current_time if schedule.processed?
            schedule.save!

            scheduler_for(schedule.entity).set_schedule schedule
          end
        end
      end if schedule
    end
  end
end
