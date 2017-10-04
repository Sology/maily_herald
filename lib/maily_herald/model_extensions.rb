module MailyHerald
  module ModelExtensions
    def self.included(base)
      unloadable
      base.class_eval do
        has_many    :maily_herald_subscriptions,       as: :entity, class_name: "MailyHerald::Subscription", dependent: :destroy
        has_many    :maily_herald_logs,                as: :entity, class_name: "MailyHerald::Log"

        after_destroy do
          self.maily_herald_logs.scheduled.destroy_all
        end
      end
    end
  end
end
