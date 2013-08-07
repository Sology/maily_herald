module MailyHerald
  class Mailing < ActiveRecord::Base
    include MailyHerald::ConditionEvaluator

    attr_accessible :name, :context_name, :autosubscribe, :subscription_group, :override_subscription,
                    :token_action, :sequence, :conditions, :mailer_name, :title, :from, :relative_delay, :template, :start, :start_var, :period

    has_many    :subscriptions, :class_name => "MailyHerald::MailingSubscription", :foreign_key => "mailing_id", :dependent => :destroy
    has_many    :logs,          :class_name => "MailyHerald::DeliveryLog", :dependent => :destroy
    
    validates   :trigger,       :presence => true, :inclusion => {:in => [:manual, :create, :save, :update, :destroy]}
    validates   :name,          :presence => true, :format => {:with => /^\w+$/}, :uniqueness => true
    validates   :title,         :presence => true
    validates   :template,      :presence => true

    def subscription_group
      read_attribute(:subscription_group).to_sym if read_attribute(:subscription_group)
    end

    def token_action
      read_attribute(:token_action).to_sym
    end

    def enabled?
      self.enabled
    end

    def periodical?
      self.class == PeriodicalMailing
    end

    def one_time?
      self.class == OneTimeMailing
    end

    def sequence?
      self.class == SequenceMailing
    end

    def context
      @context ||= MailyHerald.context context_name
    end

    def sender
      if self.from && !self.from.empty?
        self.from
      else
        MailyHerald.default_from
      end
    end

    def trigger
      read_attribute(:trigger).to_sym
    end
    def trigger=(value)
      write_attribute(:trigger, value.to_s)
    end

    def token_custom_action &block
      if block_given?
        MailyHerald.token_custom_action :mailing, self.id, &block
      else
        MailyHerald.token_custom_action :mailing, self.id
      end
    end
  end
end
