module MailyHerald
  MailyHerald::SubscriptionGroup

  class Mailing < ActiveRecord::Base

    attr_accessible :title, :subject, :context_name, :autosubscribe, :subscription_group, :override_subscription,
                    :token_action, :sequence, :conditions, :mailer_name, :title, :from, :relative_delay, :template, :start, :start_var, :period

    has_many    :subscriptions, :class_name => "MailyHerald::MailingSubscription", :foreign_key => "mailing_id", :dependent => :destroy
    has_many    :logs,          :class_name => "MailyHerald::Log", :dependent => :destroy

    belongs_to  :subscription_group, :class_name => "MailyHerald::SubscriptionGroup"
    
    validates   :trigger,       :presence => true, :inclusion => {:in => [:manual, :create, :save, :update, :destroy]}
    validates   :name,          :presence => true, :format => {:with => /^\w+$/}, :uniqueness => true
    validates   :title,         :presence => true
    validates   :subject,       :presence => true
    validates   :template,      :presence => true
    validate    :template_syntax
    validate    :validate_conditions

    scope       :enabled,       where(:enabled => true)

    before_validation do
      write_attribute(:name, self.title.downcase.gsub(/\W/, "_")) if self.title && (!self.name || self.name.empty?)
    end

    def subscription_group= g
      g = MailyHerald::SubscriptionGroup.find_by_name(g.to_s) if g.is_a?(String) || g.is_a?(Symbol)
      super(g)
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

    def has_conditions?
      self.conditions && !self.conditions.empty?
    end

    private

    def template_syntax
      begin
        template = Liquid::Template.parse(self.template)
      rescue StandardError => e
        errors.add(:template, e.to_s)
      end
    end

    def validate_conditions
      evaluator = Utils::MarkupEvaluator.test_conditions(self.conditions)
    rescue StandardError => e
      errors.add(:conditions, e.to_s) 
    end
  end
end
