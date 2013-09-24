module MailyHerald
  class SequenceSubscription < Subscription
    belongs_to  :sequence

    validates   :sequence,      :presence => true

    scope       :for_sequence,   lambda {|sequence| where(:mailing_id => sequence.id, :mailing_type => sequence.class.base_class) }

    def logs
      Log.for_entity(self.entity).where("mailing_id in (?)", self.sequence.mailings)
    end

    def logs_for mailing
      Log.for_entity(self.entity).for_mailing(self.sequence.mailings.find(mailing))
    end

    def last_processing_time
      logs.last.processed_at if logs.last
    end

    def pending_mailings 
      logs.empty? ? self.sequence.mailings.enabled : self.sequence.mailings.enabled.where("id not in (?)", logs.map(&:mailing_id))
    end

    def processed_mailings
      logs.empty? ? self.sequence.mailings.where(:id => nil) : self.sequence.mailings.where("id in (?)", logs.map(&:mailing_id))
    end

    def last_processed_mailing
      processed_mailings.last
    end

    def next_mailing
      pending_mailings.first
    end

    def mailing_log_for mailing
      Log.for_entity(self.entity).for_mailing(mailing).last
    end

    def processing_time_for mailing
      if logs.first
        logs.first.processed_at - logs.first.mailing.absolute_delay + mailing.absolute_delay
      else
        evaluator = Utils::MarkupEvaluator.new(self.sequence.context.drop_for(self.entity, self))
        evaluated_start = evaluator.evaluate_variable(self.sequence.start_var)

        if self.sequence.start && evaluated_start && (self.sequence.start > evaluated_start)
          start = self.sequence.start
        else
          start = evaluated_start
        end

        start ? start + mailing.absolute_delay : nil
      end
    end

    def next_processing_time
      if mailing = next_mailing
        processing_time_for mailing
      end
    end

    def processable?
      self.sequence.enabled? && (self.sequence.override_subscription? || active?) 
    end

    def conditions_met? mailing
      evaluator = Utils::MarkupEvaluator.new(mailing.context.drop_for(self.entity, self))
      evaluator.evaluate_conditions(mailing.conditions)
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

    def aggregated?
      !!self.sequence.subscription_group
    end

    def aggregate
      if aggregated?
        aggregate = self.sequence.subscription_group.aggregated_subscriptions.for_entity(self.entity).first
        unless aggregate
          aggregate = self.sequence.subscription_group.aggregated_subscriptions.build
          aggregate.entity = self.entity
          if self.sequence.autosubscribe && self.sequence.context.scope.include?(self.entity)
            aggregate.active = true
            aggregate.save!
          end
        end
        aggregate
      end
    end
  end
end
