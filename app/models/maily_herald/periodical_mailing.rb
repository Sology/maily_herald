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

    def deliver_to entity
      super(entity)
    end

    def deliver_with_mailer_to entity
      current_time = Time.now

      schedule = schedule_for entity

      schedule.with_lock do
        # make sure schedule hasn't been processed in the meantime
        if schedule && schedule.processing_at <= current_time && schedule.scheduled?
          attrs = super(entity)
          if attrs
            schedule.attributes = attrs
            schedule.processing_at = current_time
            schedule.save!
            set_schedule_for entity, schedule
          end
        end
      end if schedule
    end

    def run
      # TODO better scope here to exclude schedules for users outside context scope
      schedules.where("processing_at <= (?)", Time.now).each do |schedule|
        if schedule.entity
          deliver_to schedule.entity
        else
          MailyHerald.logger.log_processing(schedule.mailing, {:class => schedule.entity_type, :id => schedule.entity_id}, prefix: "Removing schedule for non-existing entity") 
          schedule.destroy
        end
      end
    end

    def processed_logs entity
      Log.ordered.for_entity(entity).for_mailing(self).processed
    end

    def start_processing_time entity
      if processed_logs(entity).first
        processed_logs(entity).first.processed_at
      else
        begin
          Time.parse(self.start_at)
        rescue
          subscription = self.list.subscription_for(entity)
          evaluator = Utils::MarkupEvaluator.new(self.list.context.drop_for(entity, subscription))

          evaluator.evaluate_variable(self.start_at)
        end
      end
    end

    def last_processing_time entity
      processed_logs(entity).last.try(:processing_at)
    end

    def set_schedule_for entity, last_log = nil
      # support entity with joined subscription table for better performance
      if entity.has_attribute?(:maily_subscription_id)
        subscribed = !!entity.maily_subscription_active
      else
        subscribed = self.list.subscribed?(entity)
      end

      if !self.period || !self.start_at || !enabled? || !(self.override_subscription? || subscribed)
        log = schedule_for(entity)
        log.try(:destroy)
        return
      end

      log = schedule_for(entity)
      last_log ||= processed_logs(entity).last

      log ||= Log.new
      log.with_lock do
        log.set_attributes_for(self, entity, {
          status: :scheduled,
          processing_at: calculate_processing_time(entity, last_log)
        })
        log.save!
      end
      log
    end

    def update_schedules
      self.list.context.scope_with_subscription(self.list, :outer).each do |entity|
        MailyHerald.logger.debug "Updating schedule of #{self} periodical for entity ##{entity.id} #{entity}"
        set_schedule_for entity
      end
    end

    def update_schedules_callback
      Rails.env.test? ? update_schedules : MailyHerald::ScheduleUpdater.perform_in(10.seconds, self.id)
    end

    def schedule_for entity
      schedules.for_entity(entity).first
    end

    def schedules
      Log.ordered.scheduled.for_mailing(self)
    end

    def calculate_processing_time entity, last_log = nil
      last_log ||= processed_logs(entity).last

      if last_log && last_log.processing_at
        last_log.processing_at + self.period
      elsif start_processing_time(entity)
        start_processing_time(entity)
      else
        nil
      end
    end

    def next_processing_time entity
      schedule_for(entity).processing_at
    end

    def to_s
      "<PeriodicalMailing: #{self.title || self.name}>"
    end
  end
end
