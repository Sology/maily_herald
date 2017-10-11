module MailyHerald
  class PeriodicalMailing::Scheduler
    def initialize mailing, entity
      @mailing = mailing
      @entity = entity
    end

    # Returns collection of processed {Log}s.
    def processed_logs
      Log.ordered.for_entity(entity).for_mailing(mailing).processed
    end

    # Calculates processing time for given entity.
    def calculate_processing_time last_log = nil
      last_log ||= processed_logs.last

      spt = start_processing_time

      if last_log && last_log.processing_at
        last_log.processing_at + mailing.period
      elsif mailing.individual_scheduling? && spt
        spt
      elsif mailing.general_scheduling?
        if spt >= Time.now
          spt
        else
          diff = (Time.now - spt).to_f
          spt ? spt + ((diff/mailing.period).ceil * mailing.period) : nil
        end
      else
        nil
      end
    end

    # Gets the timestamp of last processed email for given entity.
    def last_processing_time
      processed_logs.last.try(:processing_at)
    end

    # Returns processing time.
    #
    # This is the time when next mailing should be sent.
    # Calculation is done based on last processed mailing for entity or
    # {#start_at} mailing attribute.
    def start_processing_time
      if processed_logs.first
        processed_logs.first.processing_at
      else
        if mailing.has_start_at_proc?
          mailing.start_at.call(entity, subscription)
        else
          evaluator = Utils::MarkupEvaluator.new(list.context.drop_for(entity, subscription))
          evaluator.evaluate_start_at(mailing.start_at)
        end
      end
    end

    # Get next email processing time for given entity.
    def next_processing_time
      schedule.processing_at if schedule
    end

    # Sets the delivery schedule
    #
    # New schedule will be created or existing one updated.
    #
    # Schedule is {Log} object of type "schedule".
    def set_schedule last_log = nil
      log = schedule
      last_log ||= processed_logs.last
      processing_at = calculate_processing_time(last_log)

      if !mailing.period || !mailing.start_at || !mailing.enabled? || !processing_at || !(mailing.override_subscription? || subscribed?)
        log.try(:destroy)
        return
      end

      log ||= Log.new
      log.with_lock do
        log.set_attributes_for(mailing, entity, {
          status: :scheduled,
          processing_at: processing_at,
        })
        log.save!
      end
      log
    end

    # Returns {Log} object which is the delivery schedule.
    def schedule
      @schedule ||= mailing.schedules.for_entity(entity).first
    end

    private

    attr_reader :mailing, :entity
    delegate :list, to: :mailing

    def subscription
      @subscription ||= list.subscription_for(entity)
    end

    def subscribed?
      @subscribed ||= list.subscribed?(entity)
    end
  end
end
