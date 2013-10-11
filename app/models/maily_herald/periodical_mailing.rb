module MailyHerald
  class PeriodicalMailing < Mailing
    attr_accessible :start, :start_var, :start_text, :period, :period_in_days

    validates   :context_name, :presence => true
    validates   :period, :presence => true, :numericality => {:greater_than => 0}

    def start_text
      @start_text || self.start.strftime(MailyHerald::TIME_FORMAT) if self.start
    end
    def start_text= date
      if date && !date.empty?
        date = Time.zone.parse(date) if date.is_a?(String)
        write_attribute(:start, date)
      else
        write_attribute(:start, nil)
      end
    end

    def period_in_days
      "%.2f" % (self.period.to_f / 1.day.seconds)
    end
    def period_in_days= d
      self.period = d.to_f.days
    end

    def context
      @context ||= MailyHerald.context self.context_name
    end

    def deliver_to entity
      current_time = Time.now
      subscription = subscription_for entity
      return unless subscription.processable?

      subscription.with_lock do
        if subscription.next_processing_time && (subscription.next_processing_time <= current_time)
          super entity
        end
      end
    end

    def run
      self.context.scope.each do |entity|
        deliver_to entity
      end
    end
  end
end
