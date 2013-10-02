module MailyHerald
  MailyHerald::Subscription #TODO fix this autoload for dev

  class Sequence < Dispatch
    attr_accessible :title, :context_name, :autosubscribe, :subscription_group, :override_subscription,
                    :token_action, :conditions, :start, :start_text, :start_var, :period

    has_many    :subscriptions,       :class_name => "MailyHerald::SequenceSubscription", :foreign_key => "dispatch_id", :dependent => :destroy
    has_many    :mailings,            :class_name => "MailyHerald::SequenceMailing", :order => "absolute_delay ASC", :dependent => :destroy
    has_many    :logs,                :class_name => "MailyHerald::Log", :through => :mailings

    belongs_to  :subscription_group,  :class_name => "MailyHerald::SubscriptionGroup"

    validates   :context_name,        :presence => true
    validates   :name,                :presence => true, :format => {:with => /^\w+$/}, :uniqueness => true
    validates   :title,               :presence => true

    before_validation do
      write_attribute(:name, self.title.downcase.gsub(/\W/, "_")) if self.title && (!self.name || self.name.empty?)
    end

    after_initialize do
      if self.new_record?
        self.autosubscribe = true
        self.override_subscription = false
        self.token_action = :unsubscribe
      end
    end

    def subscription_group= g
      g = MailyHerald::SubscriptionGroup.find_by_name(g.to_s) if g.is_a?(String) || g.is_a?(Symbol)
      super(g)
    end

    def start_text= date
      if date && !date.empty?
        date = Time.zone.parse(date) if date.is_a?(String)
        write_attribute(:start, date)
      else
        write_attribute(:start, nil)
      end
    end

    def start_text
      @start_text || self.start.strftime(MailyHerald::TIME_FORMAT) if self.start
    end

    def token_action
      read_attribute(:token_action).to_sym
    end

    def context
      @context ||= MailyHerald.context context_name
    end

    def destination_for entity
      context.destination.call(entity)
    end

    def mailing name
      if SequenceMailing.table_exists?
        mailing = SequenceMailing.find_or_initialize_by_name(name)
        mailing.sequence = self
        if block_given?
          yield(mailing)
        end
        mailing.save!
        mailing
      end
    end

    def run
      current_time = Time.now
      self.context.scope.each do |entity|
        subscription = subscription_for entity
        next unless subscription.processable?

        mailing = subscription.next_mailing

        if mailing && subscription.processing_time_for(mailing) && subscription.processing_time_for(mailing) <= current_time
          mailing.deliver_to entity
        end
      end
    end

    def token_custom_action &block
      if block_given?
        MailyHerald.token_custom_action :mailing, self.id, block
      else
        MailyHerald.token_custom_action :mailing, self.id
      end
    end
  end
end
