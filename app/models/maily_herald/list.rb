module MailyHerald
  class List < ActiveRecord::Base
    attr_accessible :token_action, :context_name

    has_many :subscriptions, :class_name => "MailyHerald::Subscription"

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
