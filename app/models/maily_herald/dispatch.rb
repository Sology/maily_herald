module MailyHerald
  # Main dispatch class.
  #
  # Inherited by all {Mailing} classes.
  # Each Dispatch instance need to have associated {List}.
  # Dispatch can be in one of three states:
  # - +enabled+
  # - +disabled+
  # - +archived+
  #
  # @attr [String]    type            Polymorphic type.
  # @attr [Fixnum]    sequence_id     {Sequence} association id.
  # @attr [Fixnum]    list_id         {List} association id.
  # @attr [String]    conditions      Delivery conditions as Liquid expression.
  # @attr [String]    mailer_name     {Mailer} class name. 
  #                                   This refers to {Mailer} used by Dispatch while sending emails.
  # @attr [String]    name            Dispatch name.
  # @attr [String]    title           Dispatch title.
  # @attr [String]    from            Sender email address. 
  #                                   If not provided, action_mailer.default_options[:from} is used.
  #                                   Valid only for {Mailing}.
  # @attr [String]    state
  # @attr [String]    subject         Email subject as Liquid template.
  #                                   Valid only for {Mailing}.
  # @attr [String]    template        Email body template as Liquid template.
  #                                   Valid only for {Mailing}.
  # @attr [String]    absolute_delay  Email delivery delay from beginning of sequence.
  #                                   Valid only for {SequenceMailing}.
  # @attr [String]    period          Email delivery period.
  #                                   Valid only for {PeriodicalMailing}.
  # @attr [String]    override_subscription Defines whether email should be sent regardless of 
  #                                   entity subscription state.
  class Dispatch < ActiveRecord::Base
    belongs_to  :list,          class_name: "MailyHerald::List"

    validates   :list,          presence: true
    validates   :state,         presence: true, inclusion: {in: [:enabled, :disabled, :archived]}
    validate do |dispatch|
      dispatch.errors.add(:base, "Can't change this dispatch because it is locked.") if dispatch.changes.present? && dispatch.locked?
    end
    before_destroy do |dispatch|
      if dispatch.locked?
        dispatch.errors.add(:base, "Can't destroy this dispatch because it is locked.") 
        false
      end
    end

    delegate :subscription_for, to: :list

    scope       :enabled,       lambda { where(state: :enabled) }
    scope       :disabled,      lambda { where(state: :disabled) }
    scope       :archived,      lambda { where(state: :archived) }
    scope       :not_archived,  lambda { where("state != (?)", :archived) }

    scope       :ad_hoc_mailing, lambda { where(type: AdHocMailing) }
    scope       :one_time_mailing, lambda { where(type: OneTimeMailing) }
    scope       :periodical_mailing, lambda { where(type: PeriodicalMailing) }
    scope       :sequence,      lambda { where(type: Sequence) }

    before_validation do
      if @start_at_proc
        self.start_at = "proc"
      end
    end

    after_save do
      if @start_at_proc
        MailyHerald.start_at_procs[self.id] = @start_at_proc
      end
    end

    # Sets start_at value of {OneTimeMailing}, {PeriodicalMailing} and {SequenceMailing}.
    #
    # @param v String with Liquid expression or `Proc` that evaluates to `Time`.
    def start_at= v
      if v.respond_to? :call
        @start_at_proc = v
      else
        super(v.is_a?(Time) ? v.to_s : v)
      end
    end

    # Returns time as string with Liquid expression or Proc.
    def start_at
      @start_at_proc || MailyHerald.start_at_procs[self.id] || read_attribute(:start_at)
    end

    def has_start_at_proc?
      !!(@start_at_proc || MailyHerald.start_at_procs[self.id])
    end

    def start_at_changed?
      if has_start_at_proc?
        @start_at_proc != MailyHerald.start_at_procs[self.id]
      else
        super
      end
    end

    # Returns dispatch state as symbol
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
      update_attribute(:state, "enabled")
    end
    def disable!
      update_attribute(:state, "disabled")
    end
    def archive!
      update_attribute(:state, "archived")
    end

    def enable
      write_attribute(:state, "enabled")
    end
    def disable
      write_attribute(:state, "disabled")
    end
    def archive
      write_attribute(:state, "archived")
    end

    # Sets {List} associated with this dispatch
    #
    # @param l {List} name or {List} object
    def list= l
      l = MailyHerald::List.find_by_name(l.to_s) if l.is_a?(String) || l.is_a?(Symbol)
      super(l)
    end

    def subscription_valid? entity
      self.override_subscription? || self.list.subscribed?(entity)
    end

    def in_scope? entity
      self.list.context.scope.exists?(entity)
    end

    # Checks if dispatch can be sent to given entity.
    #
    # Following checks are performed:
    # - dispatch is enabled,
    # - subscription is overriden or user is subscribed to dispatch list,
    # - entity belongs to list {Context} scope.
    #
    # @param entity [ActiveRecord::Base] Recipient
    def processable? entity
      self.enabled? && subscription_valid?(entity) && in_scope?(entity)
    end

    # Check if dispatch is locked.
    # @see MailyHerald.dispatch_locked?
    def locked?
      MailyHerald.dispatch_locked?(self.name)
    end
  end
end
