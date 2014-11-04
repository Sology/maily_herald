module MailyHerald
  class List < ActiveRecord::Base
    include MailyHerald::Autonaming

    if Rails::VERSION::MAJOR == 3
      attr_accessible :name, :title, :token_action, :context_name
    end

    has_many :dispatches, class_name: "MailyHerald::Dispatch"
    has_many :subscriptions, class_name: "MailyHerald::Subscription"

    validates :title, presence: true
    validates :name, presence: true, format: {with: /\A[A-Za-z0-9_]+\z/}

    after_initialize do
      if self.new_record?
        self.token_action = :unsubscribe
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
      !!subscription_for(entity).try(:active?)
    end

    def subscription_for entity
      self.subscriptions.for_entity(entity).first
    end

    def token_action
      read_attribute(:token_action).to_sym
    end

    def token_custom_action &block
      if block_given?
        MailyHerald.token_custom_action :mailing, self.id, &block
      else
        MailyHerald.token_custom_action :mailing, self.id
      end
    end

    def active_subscription_count
      self.subscriptions.active.count
    end

    # Returns entities within the context's scope with active subscription
    def subscribers
      context.scope_with_subscription.where("#{Subscription.table_name}.active = (?)", true).where("#{Subscription.table_name}.list_id = (?)", self.id)
    end

    # Returns entities within the context's scope with inactive subscription
    def opt_outs
      context.scope_with_subscription.where("#{Subscription.table_name}.active = (?)", false).where("#{Subscription.table_name}.list_id = (?)", self.id)
    end

    # Returns entities within the context's scope without subscription
    def potential_subscribers
      sq = context.scope_with_subscription(:outer).where("#{Subscription.table_name}.list_id = (?)", self.id).pluck("#{context.model.table_name}.id")
      context.scope.where(context.model.arel_table[:id].not_in(sq))
    end

    def logs
      Log.for_mailings(Dispatch.where(id: self.dispatches.select("id")).select("id"))
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
