module MailyHerald
  class AdHocMailing < Mailing
    validates   :list,          presence: true

    # Schedules mailing delivery to all entities in the scope at given `time`.
    #
    # This always creates new {MailyHerald::Log} objects of type `schedule`.
    #
    # @param time [Time] time of delivery
    def schedule_delivery_to_all time = Time.now
      self.list.context.scope_with_subscription(self.list, :outer).each do |entity|
        MailyHerald.logger.debug "Adding schedule of #{self} ad-hoc for entity ##{entity.id} #{entity}"
        schedule_delivery_to entity, time
      end
    end

    # Schedules mailing delivery to `entity` at given `time`.
    #
    # This always creates new {MailyHerald::Log} object of type `schedule`.
    #
    # @param entity [ActiveRecord::Base]
    # @param time [Time] time of delivery
    def schedule_delivery_to entity, time = Time.now
      subscribed = self.list.subscribed?(entity)

      if !enabled? || !(self.override_subscription? || subscribed)
        return
      end

      log = Log.new
      log.with_lock do
        log.set_attributes_for(self, entity, {
          status: :scheduled,
          processing_at: time,
        })
        log.save!
      end
      log
    end

    # Sends mailing to all subscribed entities who have delivery scheduled.
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

    # Sets the delivery schedule for given entity
    #
    # New schedule will be created or existing one updated.
    #
    # Schedule is {Log} object of type "schedule".
    def set_schedule_for entity
      subscribed = self.list.subscribed?(entity)

      if !enabled? || !(self.override_subscription? || subscribed)
        log = schedule_for(entity)
        log.try(:destroy)
        return
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

    def to_s
      "<AdHocMailing: #{self.title || self.name}>"
    end

    private

    def deliver_with_mailer schedule
      current_time = Time.now

      schedule.with_lock do
        # make sure schedule hasn't been processed in the meantime
        if schedule && schedule.processing_at <= current_time && schedule.scheduled?
          attrs = super(schedule)
          if attrs
            schedule.attributes = attrs
            schedule.processing_at = current_time
            schedule.save!
          end
        end
      end if schedule
    end

  end
end
