module MailyHerald
  class SequenceSubscription < Subscription
    belongs_to  :sequence

    validates   :sequence,      :presence => true

    scope       :for_sequence,   lambda {|sequence| where(:mailing_id => sequence.id, :mailing_type => sequence.class.base_class) }

    def logs
      DeliveryLog.for_entity(self.entity).where("mailing_id in (?)", self.sequence.mailings)
    end

    def logs_for mailing
      DeliveryLog.for_entity(self.entity).for_mailing(self.sequence.mailings.find(mailing))
    end

    def last_delivery_time
      logs.last.delivered_at if logs.last
    end

    def pending_mailings 
      logs.empty? ? self.sequence.mailings.enabled : self.sequence.mailings.enabled.where("id not in (?)", logs.map(&:mailing_id))
    end

    def delivered_mailings
      logs.empty? ? self.sequence.mailings.where(:id => nil) : self.sequence.mailings.where("id in (?)", logs.map(&:mailing_id))
    end

    def last_delivered_mailing
      delivered_mailings.last
    end

    def next_mailing
      pending_mailings.first
    end

    def mailing_log_for mailing
      DeliveryLog.for_entity(self.entity).for_mailing(mailing).last
    end

    def delivery_time_for mailing
      if last_delivered_mailing
        mailings = self.sequence.mailings.enabled.where("position > (?)", last_delivered_mailing.position).where("position < (?)", mailing.position)
        delay_sum = mailings.sum(:relative_delay)
        log = mailing_log_for(last_delivered_mailing)
        log.delivered_at + delay_sum + mailing.relative_delay
      else
        mailings = self.sequence.mailings.enabled.where("position < (?)", mailing.position)
        delay_sum = mailings.sum(:relative_delay)

        if self.sequence.start
          start = self.sequence.start
        else
          evaluator = Utils::MarkupEvaluator.new(self.sequence.context.drop_for(self.entity, self))
          start = evaluator.evaluate_variable(self.sequence.start_var)
        end
        if start
          start + delay_sum + mailing.relative_delay
        else
          nil
        end
      end
    end

    def next_delivery_time
      if mailing = next_mailing
        delivery_time_for mailing
      end
    end

    def deliverable?
      self.sequence.enabled? && (self.sequence.override_subscription? || active?) 
    end

    def destination 
      self.sequence.context.destination.call(self.entity)
    end

    def render_template mailing
      drop = self.sequence.context.drop_for self.entity, self
      template = Liquid::Template.parse(mailing.template)
      template.render drop
    end

    def target
      self.sequence
    end
  end
end
