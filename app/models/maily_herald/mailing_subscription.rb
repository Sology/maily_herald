module MailyHerald
  class MailingSubscription < Subscription
    include MailyHerald::TemplateRenderer

    belongs_to  :mailing,       :foreign_key => :dispatch_id

    validates   :mailing,       :presence => true

    scope       :for_mailing,   lambda {|mailing| where(:mailing_id => mailing.id, :mailing_type => mailing.class.base_class) }

    def logs
      Log.for_entity(self.entity).for_mailing(self.mailing)
    end

    def start_processing_time
      if logs.first
        logs.first.processed_at
      else
        evaluator = Utils::MarkupEvaluator.new(self.mailing.context.drop_for(self.entity, self))
        evaluated_start = evaluator.evaluate_variable(self.mailing.start_var)

        if self.mailing.start && evaluated_start && (self.mailing.start > evaluated_start)
          self.mailing.start
        else
          evaluated_start
        end
      end
    end

    def last_processing_time
      logs.last.processed_at if logs.last
    end

    def next_processing_time
      return unless self.mailing.period

      log = logs.last
      if log && log.processed_at
        log.processed_at + self.mailing.period
      elsif start_processing_time
        start_processing_time
      else
        nil
      end
    end

    def processable?
      self.mailing.enabled? && (self.mailing.override_subscription? || active?)
    end

    def conditions_met?
      evaluator = Utils::MarkupEvaluator.new(self.mailing.context.drop_for(self.entity, self))
      evaluator.evaluate_conditions(self.mailing.conditions)
    end

    def destination 
      self.mailing.context.destination.call(self.entity)
    end

    def render_template
      drop = self.mailing.context.drop_for self.entity, self
      perform_template_rendering drop, self.mailing.template
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
