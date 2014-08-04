module MailyHerald
  module ModelExtensions
    module AssociationsPatch
      def self.included(base)
        unloadable
        base.class_eval do
          has_many    :maily_herald_subscriptions,       :as => :entity, :class_name => "MailyHerald::Subscription", :dependent => :destroy
          has_many    :maily_herald_logs,                :as => :entity, :class_name => "MailyHerald::Log", :dependent => :destroy
        end
      end
    end
  end
end
