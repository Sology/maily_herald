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
    validates   :name,                presence: true, format: {with: /\A\w+\z/}, uniqueness: true
    validates   :title,               presence: true

    before_validation do
      write_attribute(:name, self.title.downcase.gsub(/\W/, "_")) if self.title && (!self.name || self.name.empty?)
    end

    after_initialize do
      if self.new_record?
        self.override_subscription = false
      end
    end
    after_save :update_schedules, if: Proc.new{|s| s.state_changed? || s.start_at_changed?}

    def mailing name
      if SequenceMailing.table_exists?
        mailing = SequenceMailing.find_or_initialize_by_name(name)
        mailing.sequence = self
        if block_given?
          yield(mailing)
          mailing.save! if mailing.new_record?
        end
        mailing
      end
    end

    def run
      schedules.where("processing_at <= (?)", Time.now).each do |schedule|
        schedule.mailing.deliver_to schedule.entity
      end
    end

    def processed_logs entity
      Log.ordered.processed.for_entity(entity).for_mailings(self.mailings.select(:id))
    end

    def processed_logs_for entity, mailing
      Log.ordered.processed.for_entity(entity).for_mailing(self.mailings.find(mailing))
    end

    def last_processing_time entity
      ls = processed_logs(entity)
      ls.last.processing_at if ls.last
    end

    def pending_mailings entity
      ls = processed_logs(entity)
      ls.empty? ? self.mailings.enabled : self.mailings.enabled.where("id not in (?)", ls.map(&:mailing_id))
    end

    def processed_mailings entity
      ls = processed_logs(entity)
      ls.empty? ? self.mailings.where(id: nil) : self.mailings.where("id in (?)", ls.map(&:mailing_id))
    end

    def last_processed_mailing entity
      processed_mailings(entity).last
    end

    def next_mailing entity
      pending_mailings(entity).first
    end

    def mailing_processing_log_for entity, mailing
      Log.ordered.processed.for_entity(entity).for_mailing(mailing).last
    end

    def set_schedule_for entity
      log = schedule_for(entity)
      mailing = next_mailing(entity)

      if !mailing || !self.start_at || !enabled?
        log.try(:destroy)
        return
      end

      log ||= Log.new
      log.set_attributes_for(mailing, entity, {
        status: :scheduled,
        processing_at: calculate_processing_time_for(entity, mailing)
      })
      log.save!
      log
    end

    def update_schedules
      self.list.context.scope.each do |entity|
        MailyHerald.logger.debug "Updating schedule of #{self} sequence for entity #{entity}"
        set_schedule_for entity
      end
    end

    def schedule_for entity
      schedules.for_entity(entity).first
    end

    def schedules
      Log.ordered.scheduled.for_mailings(self.mailings.select(:id))
    end

    def calculate_processing_time_for entity, mailing = nil
      mailing ||= next_mailing(entity)
      ls = processed_logs(entity)

      if ls.first
        ls.last.processing_at + (mailing.absolute_delay - ls.last.mailing.absolute_delay)
      else
        begin
          Time.parse(self.start_at) + mailing.absolute_delay
        rescue
          subscription = self.list.subscription_for(entity)
          evaluator = Utils::MarkupEvaluator.new(self.list.context.drop_for(entity, subscription))
          evaluated_start = evaluator.evaluate_variable(self.start_at)

          evaluated_start + mailing.absolute_delay
        end
      end
    end

    def next_processing_time entity
      schedule_for(entity).try(:processing_at)
    end

    def to_s
      "<Sequence: #{self.title || self.name}>"
    end
  end
end
