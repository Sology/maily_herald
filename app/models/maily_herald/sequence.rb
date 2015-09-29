module MailyHerald
  MailyHerald::Subscription #TODO fix this autoload for dev

  class Sequence < Dispatch
    if Rails::VERSION::MAJOR == 3
      attr_accessible :name, :title, :override_subscription,
                      :conditions, :start_at, :period
    end

    include MailyHerald::Autonaming

    has_many    :logs,                class_name: "MailyHerald::Log", through: :mailings
    if Rails::VERSION::MAJOR == 3
      has_many    :mailings,          class_name: "MailyHerald::SequenceMailing", order: "absolute_delay ASC", dependent: :destroy
    else
      has_many    :mailings,          -> { order("absolute_delay ASC") }, class_name: "MailyHerald::SequenceMailing", dependent: :destroy
    end

    validates   :list,                presence: true

    before_validation do
      write_attribute(:name, self.title.downcase.gsub(/\W/, "_")) if self.title && (!self.name || self.name.empty?)
    end

    after_initialize do
      if self.new_record?
        self.override_subscription = false
      end
    end
    after_save :update_schedules_callback, if: Proc.new{|s| s.state_changed? || s.start_at_changed?}

    # Fetches or defines an {SequenceMailing}.
    #
    # If no block provided, {SequenceMailing} with given +name+ is returned.
    #
    # If block provided, {SequenceMailing} with given +name+ is created or edited 
    # and block is evaluated within that mailing.
    #
    # @option options [true, false] :locked (false) Determines whether Mailing is locked.
    # @see Dispatch#locked?
    def mailing name, options = {}
      if SequenceMailing.table_exists?
        mailing = SequenceMailing.find_by_name(name)
        lock = options.delete(:locked)

        if block_given? && !MailyHerald.dispatch_locked?(name) && (!mailing || lock)
          mailing ||= self.mailings.build(name: name)
          mailing.sequence = self
          yield(mailing)
          mailing.skip_updating_schedules = true if self.new_record?
          mailing.save!

          MailyHerald.lock_dispatch(name) if lock
        end

        mailing
      end
    end

    # Sends sequence mailings to all subscribed entities.
    #
    # Performs actual sending of emails; should be called in background.
    #
    # Returns array of {MailyHerald::Log} with actual `Mail::Message` objects stored
    # in {MailyHerald::Log.mail} attributes.
    def run
      # TODO better scope here to exclude schedules for users outside context scope
      schedules.where("processing_at <= (?)", Time.now).each do |schedule|
        if schedule.entity
          mail = schedule.mailing.send(:deliver, schedule)
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
      Log.ordered.processed.for_entity(entity).for_mailings(self.mailings.select(:id))
    end

    # Returns collection of processed {Log}s for given entity and mailing.
    #
    # @param entity [ActiveRecord::Base]
    # @param mailing [SequenceMailing]
    def processed_logs_for entity, mailing
      Log.ordered.processed.for_entity(entity).for_mailing(self.mailings.find(mailing))
    end

    # Gets the timestamp of last processed email for given entity.
    def last_processing_time entity
      ls = processed_logs(entity)
      ls.last.processing_at if ls.last
    end

    # Gets collection of {SequenceMailing} objects that are to be sent to entity.
    def pending_mailings entity
      ls = processed_logs(entity)
      ls.empty? ? self.mailings.enabled : self.mailings.enabled.where("id not in (?)", ls.map(&:mailing_id))
    end

    # Gets collection of {SequenceMailing} objects that were sent to entity.
    def processed_mailings entity
      ls = processed_logs(entity)
      ls.empty? ? self.mailings.where(id: nil) : self.mailings.where("id in (?)", ls.map(&:mailing_id))
    end

    # Gets last {SequenceMailing} object delivered to user.
    def last_processed_mailing entity
      processed_mailings(entity).last
    end

    # Gets next {SequenceMailing} object to be delivered to user.
    def next_mailing entity
      pending_mailings(entity).first
    end

    def mailing_processing_log_for entity, mailing
      Log.ordered.processed.for_entity(entity).for_mailing(mailing).last
    end

    # Sets the delivery schedule for given entity
    #
    # New schedule will be created or existing one updated.
    #
    # Schedule is {Log} object of type "schedule".
    def set_schedule_for entity
      # TODO handle override subscription?

      subscribed = self.list.subscribed?(entity)
      mailing = next_mailing(entity)
      start_time = calculate_processing_time_for(entity, mailing) if mailing

      if !subscribed || !self.start_at || !enabled? || !mailing || !start_time 
        log = schedule_for(entity)
        log.try(:destroy)
        return
      end

      log = schedule_for(entity)
      log ||= Log.new
      log.with_lock do
        log.set_attributes_for(mailing, entity, {
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
        MailyHerald.logger.debug "Updating schedule of #{self} sequence for entity ##{entity.id} #{entity}"
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
      Log.ordered.scheduled.for_mailings(self.mailings.select(:id))
    end

    # Calculates processing time for given entity.
    def calculate_processing_time_for entity, mailing = nil
      mailing ||= next_mailing(entity)
      ls = processed_logs(entity)

      if ls.first
        ls.last.processing_at + (mailing.absolute_delay - ls.last.mailing.absolute_delay)
      else
        subscription = self.list.subscription_for(entity)

        if has_start_at_proc?
          evaluated_start = start_at.call(entity, subscription)
        else
          evaluator = Utils::MarkupEvaluator.new(self.list.context.drop_for(entity, subscription))

          evaluated_start = evaluator.evaluate_start_at(self.start_at)
        end

        evaluated_start ? evaluated_start + mailing.absolute_delay : nil
      end
    end

    # Get next email processing time for given entity.
    def next_processing_time entity
      schedule_for(entity).try(:processing_at)
    end

    def to_s
      "<Sequence: #{self.title || self.name}>"
    end
  end
end
