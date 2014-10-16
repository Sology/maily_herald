module MailyHerald
  class Dispatch < ActiveRecord::Base
    belongs_to  :list,          class_name: "MailyHerald::List"

    validates   :name,          presence: true, format: {with: /\A\w+\z/}, uniqueness: true
    validates   :list,          presence: true
    validates   :state,         presence: true, inclusion: {in: [:enabled, :disabled, :archived]}

    delegate :subscription_for, to: :list

    scope       :enabled,       lambda { where(state: :enabled) }
    scope       :disabled,      lambda { where(state: :disabled) }
    scope       :archived,      lambda { where(state: :archived) }

    def state
      read_attribute(:state).to_sym
    end

    def enabled?
      self.state == :enabled
    end
    def disabled?
      self.state == :disabled
    end
    def archived?
      self.state == :archived
    end

    def enable!
      update_attribute(:state, :enabled)
    end
    def disable!
      update_attribute(:state, :disabled)
    end
    def archive!
      update_attribute(:state, :archived)
    end

    def enable
      write_attribute(:state, :enabled)
    end
    def disable
      write_attribute(:state, :disabled)
    end
    def archive
      write_attribute(:state, :archived)
    end

    def list= l
      l = MailyHerald::List.find_by_name(l.to_s) if l.is_a?(String) || l.is_a?(Symbol)
      super(l)
    end

    def processable? entity
      self.enabled? && (self.override_subscription? || self.list.subscribed?(entity)) && self.list.context.scope.include?(entity)
    end

  end
end
