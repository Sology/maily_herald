module MailyHerald
  class PeriodicalMailing < Mailing
    attr_accessible :start_at, :period, :period_in_days

    validates   :list,          :presence => true
    validates   :period,        :presence => true, :numericality => {:greater_than => 0}

    after_update :update_schedules, :if => Proc.new{|m| m.period_changed? || m.start_at_changed?}

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
      subscription = subscription_for entity
      return unless subscription

      schedule = schedule_for entity

      subscription.with_lock do
        if schedule.processing_at <= current_time
          attrs = super(entity)
          if attrs
            schedule.attributes = attrs
            schedule.processing_at = current_time
            schedule.save!
            set_schedule_for entity, schedule
          end
        end
      end
    end

    def run
      schedules.where("processing_at <= (?)", Time.now).each do |schedule|
        deliver_to schedule.entity
      end
    end

    def processed_logs entity
      Log.for_entity(entity).for_mailing(self).processed
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
      return unless self.period

      last_log ||= processed_logs(entity).last

      log = schedule_for(entity) || Log.new
      log.mailing = self
      log.entity = entity
      log.status = :scheduled
      log.processing_at = calculate_processing_time(entity, last_log)
      log.save!
      log
    end

    def update_schedules
      Log.scheduled.for_mailing(self).each do |log|
        log.update_attribute :processing_at, calculate_processing_time(log.entity)
      end
    end

    def schedule_for entity
      schedules.for_entity(entity).first
    end

    def schedules
      Log.scheduled.for_mailing(self)
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
  end
end
