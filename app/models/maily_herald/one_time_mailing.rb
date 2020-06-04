module MailyHerald
  class OneTimeMailing < MailyHerald::Mailing
    validates   :list,          presence: true
    validates   :start_at,      presence: true
    validate    :validate_start_at

    after_save :update_schedules_callback, if: Proc.new{|m| m.check_changed_attribute(m, :state) || m.check_changed_attribute(m, :start_at)}

    # Sends mailing to all subscribed entities.
    #
    # Performs actual sending of emails; should be called in background.
    #
    # Returns array of {MailyHerald::Log} with actual `Mail::Message` objects stored
    # in {MailyHerald::Log.mail} attributes.
    def run
      is_static_start_at = true
      is_static_start_at = false unless start_at
      is_static_start_at = false if has_start_at_proc?
      parsed_start_at = nil
      begin
        parsed_start_at = Time.parse(start_at)
      rescue ArgumentError => e
        is_static_start_at = false
      rescue Exception => e
        is_static_start_at = false
      end

      method_to_invoke_after_scheduling = nil
      if is_static_start_at && parsed_start_at
        return if pending? && Time.now < parsed_start_at
        method_to_invoke_after_scheduling = (Time.now < parsed_start_at) ? :pend! : :complete!
      end

      delivery_scope.collect do |entity|
        schedule = MailyHerald::Log.get_from(entity)
        schedule ||= set_schedule_for(entity)

        if schedule && schedule.processing_at <= Time.now
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

      send(method_to_invoke_after_scheduling) if method_to_invoke_after_scheduling
    end

    # Returns collection of processed {Log}s for given entity.
    def processed_logs entity
      Log.ordered.for_entity(entity).for_mailing(self).processed
    end

    # Sets the delivery schedule for given entity
    #
    # New schedule will be created or existing one updated.
    # Schedule is {Log} object of type "schedule".
    def set_schedule_for entity
      if processed_logs(entity).last
        # this mailing is sent only once
        log = schedule_for(entity)
        log.try(:destroy)
        return
      end

      subscribed = self.list.subscribed?(entity)
      start_time = start_processing_time(entity)

      if !self.start_at || !enabled? || completed? || !start_time || !subscribed
        log = schedule_for(entity)
        log.try(:destroy)
        return
      end

      log = schedule_for(entity)

      log ||= Log.new
      log.with_lock do
        log.set_attributes_for(self, entity, {
          status: :scheduled,
          processing_at: start_time,
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
        MailyHerald.logger.debug "Updating schedule of #{self} one-time for entity ##{entity.id} #{entity}"
        set_schedule_for entity
      end
    end

    # Returns {Log} object which is the delivery schedule for given entity.
    def schedule_for entity
      schedules.for_entity(entity).first
    end

    # Returns collection of all delivery schedules ({Log} collection).
    def schedules
      Log.ordered.scheduled.for_mailing(self)
    end

    # Returns processing time for given entity.
    #
    # This is the time when next mailing should be sent based on
    # {#start_at} mailing attribute.
    def start_processing_time entity
      subscription = self.list.subscription_for(entity)

      if has_start_at_proc?
        start_at.call(entity, subscription)
      else
        evaluator = Utils::MarkupEvaluator.new(self.list.context.drop_for(entity, subscription))

        evaluator.evaluate_start_at(self.start_at)
      end
    end

    def delivery_scope
      list.context.scope_with_log(self, :outer, subscription_active: true, log_status: [nil, :scheduled]).where("#{MailyHerald::Log.table_name}.processing_at IS NULL OR #{MailyHerald::Log.table_name}.processing_at <= (?)", Time.now)
    end

    def to_s
      "<OneTimeMailing: #{self.title || self.name}>"
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
          end
        end
      end if schedule
    end

    def update_schedules_callback
      Rails.env.test? ? set_schedules : MailyHerald::ScheduleUpdater.perform_in(10.seconds, self.id)
    end
  end
end
