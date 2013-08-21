module MailyHerald
  class MailingSubscription < Subscription
    belongs_to  :mailing

    validates   :mailing,       :presence => true

    scope       :for_mailing,   lambda {|mailing| where(:mailing_id => mailing.id, :mailing_type => mailing.class.base_class) }

    def logs
      DeliveryLog.for_entity(self.entity).for_mailing(self.mailing)
    end

    def start_delivery_time
      if self.mailing.start
        self.mailing.start
      else
        evaluator = Utils::MarkupEvaluator.new(self.mailing.context.drop_for(self.entity, self))
        evaluator.evaluate_variable(self.mailing.start_var)
      end
    end

    def last_delivery_time
      logs.last.delivered_at if logs.last
    end

    def next_delivery_time
      return unless self.mailing.period

      log = logs.last
      if log && log.delivered_at
        log.delivered_at + self.mailing.period
      elsif start_delivery_time
        start_delivery_time
      else
        nil
      end
    end

    def deliverable?
      self.mailing.enabled? && (self.mailing.override_subscription? || active?) && conditions_met?
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

    def aggregated?
      !!self.mailing.subscription_group
    end

    def aggregate
      if aggregated?
        aggregate = self.mailing.subscription_group.aggregated_subscriptions.for_entity(self.entity).first
        unless aggregate
          aggregate = self.mailing.subscription_group.aggregated_subscriptions.build
          aggregate.entity = self.entity
          if self.mailing.autosubscribe && self.mailing.context.scope.include?(self.entity)
            aggregate.active = true
            aggregate.save!
          end
        end
        aggregate
      end
    end
  end
end
