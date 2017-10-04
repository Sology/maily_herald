module MailyHerald
  class PeriodicalMailing < Mailing
    if Rails::VERSION::MAJOR == 3
      attr_accessible :period, :period_in_days
    end

    validates   :list,          presence: true
    validates   :start_at,      presence: true
    validates   :period,        presence: true, numericality: {greater_than: 0}

    after_save :update_schedules_callback, if: Proc.new{|m| m.state_changed? || m.period_changed? || m.start_at_changed? || m.override_subscription?}

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

    # Returns collection of processed {Log}s for given entity.
    def processed_logs entity
      Log.ordered.for_entity(entity).for_mailing(self).processed
    end

    # Returns processing time for given entity.
    #
    # This is the time when next mailing should be sent.
    # Calculation is done mased on last processed mailing for this entity or
    # {#start_at} mailing attribute.
    def start_processing_time entity
      if processed_logs(entity).first
        processed_logs(entity).first.processing_at
      else
        subscription = self.list.subscription_for(entity)

        if has_start_at_proc?
          start_at.call(entity, subscription)
        else
          evaluator = Utils::MarkupEvaluator.new(self.list.context.drop_for(entity, subscription))

          evaluator.evaluate_start_at(self.start_at)
        end
      end
    end

    # Gets the timestamp of last processed email for given entity.
    def last_processing_time entity
      processed_logs(entity).last.try(:processing_at)
    end

    # Sets the delivery schedule for given entity
    #
    # New schedule will be created or existing one updated.
    #
    # Schedule is {Log} object of type "schedule".
    def set_schedule_for entity, last_log = nil
      subscribed = self.list.subscribed?(entity)
      log = schedule_for(entity)
      last_log ||= processed_logs(entity).last
      processing_at = calculate_processing_time(entity, last_log)

      if !self.period || !self.start_at || !enabled? || !processing_at || !(self.override_subscription? || subscribed)
        log = schedule_for(entity)
        log.try(:destroy)
        return
      end

      log ||= Log.new
      log.with_lock do
        log.set_attributes_for(self, entity, {
          status: :scheduled,
          processing_at: processing_at,
        })
        log.save!
      end
      log
    end

    # Sets delivery schedules of all entities in mailing scope.
    #
    # New schedules will be created or existing ones updated.
    def set_schedules
      self.list.context.scope_with_subscription(self.list, :outer).each do |entity|
        MailyHerald.logger.debug "Updating schedule of #{self} periodical for entity ##{entity.id} #{entity}"
        set_schedule_for entity
      end
    end

    def update_schedules_callback
      Rails.env.test? ? set_schedules : MailyHerald::ScheduleUpdater.perform_in(10.seconds, self.id)
    end

    # Returns {Log} object which is the delivery schedule for given entity.
    def schedule_for entity
      schedules.for_entity(entity).first
    end

    # Returns collection of all delivery schedules ({Log} collection).
    def schedules
      Log.ordered.scheduled.for_mailing(self)
    end

    # Calculates processing time for given entity.
    def calculate_processing_time entity, last_log = nil
      last_log ||= processed_logs(entity).last

      spt = start_processing_time(entity)

      if last_log && last_log.processing_at
        last_log.processing_at + self.period
      elsif individual_scheduling? && spt
        spt
      elsif general_scheduling?
        if spt >= Time.now
          spt
        else
          diff = (Time.now - spt).to_f
          spt ? spt + ((diff/self.period).ceil * self.period) : nil
        end
      else
        nil
      end
    end

    # Get next email processing time for given entity.
    def next_processing_time entity
      schedule_for(entity).processing_at
    end

    def to_s
      "<PeriodicalMailing: #{self.title || self.name}>"
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

            set_schedule_for schedule.entity, schedule
          end
        end
      end if schedule
    end
  end
end
