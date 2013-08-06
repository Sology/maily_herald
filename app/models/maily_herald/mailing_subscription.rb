module MailyHerald
  class MailingSubscription < Subscription
    belongs_to  :mailing

    validates   :mailing,       :presence => true

    scope       :for_mailing,   lambda {|mailing| where(:mailing_id => mailing.id, :mailing_type => mailing.class.base_class) }

    def logs
      DeliveryLog.for_entity(self.entity).for_mailing(self.mailing)
    end

    def start_delivery_time
      evaluator = Utils::MarkupEvaluator.new(self.mailing.context.drop_for(self.entity, self))
      evaluator.evaluate_variable(self.mailing.start_var)
    end

    def last_delivery_time
      logs.last.delivered_at if logs.last
    end

    def next_delivery_time
      return unless self.mailing.period

      log = logs.last
      if log && log.delivered_at
        log.delivered_at + self.mailing.period
      else
        start_delivery_time + self.mailing.period
      end
    end

    def deliverable?
      self.mailing.enabled? && active? && conditions_met?
    end

    def conditions_met?
      self.mailing.evaluate_conditions_for(self.entity)
    end

    def destination 
      self.mailing.context.destination.call(self.entity)
    end

    def render_template
      drop = self.mailing.context.drop_for self.entity, self
      template = Liquid::Template.parse(self.mailing.template)
      template.render drop
    end

    def target
      self.mailing
    end
  end
end
