module MailyHerald
  class List < ActiveRecord::Base
    include MailyHerald::Autonaming

    if Rails::VERSION::MAJOR == 3
      attr_accessible :name, :title, :context_name
    end

    has_many :dispatches, class_name: "MailyHerald::Dispatch"
    has_many :subscriptions, class_name: "MailyHerald::Subscription"

    validate do |list|
      list.errors.add(:base, "Can't change this list because it is locked.") if list.locked?
    end
    before_destroy do |list|
      if list.locked?
        list.errors.add(:base, "Can't destroy this list because it is locked.") 
        false
      end
    end

    def context
      @context ||= MailyHerald.context self.context_name
    end

    def subscribe! entity
      s = subscription_for(entity) 
      s ? s.activate! : s = create_subscription_for(entity, true)
      s
    end

    def unsubscribe! entity
      s = subscription_for(entity) 
      s ? s.deactivate! : s = create_subscription_for(entity, false)
      s
    end

    def subscribed? entity
      subscription_for(entity).try(:active?)
    end

    # true if user has inactive subscription or never been subscribed
    def unsubscribed? entity
      s = subscription_for(entity)
      s ? !s.active? : true
    end

    # true only if user was intentionally unsubscribed
    def opted_out? entity
      s = subscription_for(entity)
      s ? !s.active? : false
    end

    def subscription_for entity
      self.subscriptions.for_entity(entity).first
    end

    def active_subscription_count
      subscribers.count(:id)
    end

    # Returns entities within the context's scope with active subscription
    def subscribers
      context.scope_with_subscription(self).where("#{Subscription.table_name}.active = (?)", true).where("#{Subscription.table_name}.list_id = (?)", self.id)
    end

    # Returns entities within the context's scope with inactive subscription
    def opt_outs
      context.scope_with_subscription(self).where("#{Subscription.table_name}.active = (?)", false).where("#{Subscription.table_name}.list_id = (?)", self.id)
    end

    # Returns entities within the context's scope without subscription
    def potential_subscribers
      sq = context.scope_with_subscription(self, :outer).where("#{Subscription.table_name}.list_id = (?)", self.id).pluck("#{context.model.table_name}.id")
      context.scope.where(context.model.arel_table[:id].not_in(sq))
    end

    def logs
      #Log.for_mailings(self.dispatches.select("id"))
      Log.for_mailings(Dispatch.where("sequence_id IN (?) OR list_id = (?)", Sequence.where(list_id: self.id).select("id"), self.id).select("id"))
    end

    def locked?
      MailyHerald.list_locked?(self.name)
    end

    private

    def create_subscription_for entity, active = false
      s = self.subscriptions.build.tap do |s|
        s.entity = entity
        s.active = active
      end
      s.save!
      s
    end

  end
end
