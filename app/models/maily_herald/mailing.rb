module MailyHerald
  class Mailing < MailyHerald::Dispatch
    include MailyHerald::TemplateRenderer
    include MailyHerald::Autonaming

    enum kind: [:mixed, :plain, :html]

    validates   :subject,         presence: true, if: :generic_mailer?
    validates   :template_plain,  presence: { if: -> { template_html.blank? && generic_mailer? } }
    validates   :template_html,   presence: { if: -> { template_plain.blank? && generic_mailer? } }
    validate    :mailer_validity
    validate    :template_syntax
    validate    :validate_conditions

    before_validation do
      write_attribute(:name, self.title.downcase.gsub(/\W/, "_")) if self.title && (!self.name || self.name.empty?)
      write_attribute(:conditions, nil) if !self.has_conditions_proc? && self.conditions.try(:empty?)
      write_attribute(:from, nil) if self.from.try(:empty?)
      write_attribute(:template_plain, nil) if self.html?
      write_attribute(:template_html, nil) if self.plain?
    end

    after_initialize do
      if self.new_record?
        self.mailer_name = :generic
      end

      if @conditions_proc
        self.conditions = "proc"
      end
    end

    after_save do
      if @conditions_proc
        MailyHerald.conditions_procs[self.id] = @conditions_proc
      end
    end

    # Sets mailing conditions.
    #
    # @param v String with Liquid expression or `Proc` that evaluates to `true` or `false`.
    def conditions= v
      if v.respond_to? :call
        @conditions_proc = v
      else
        write_attribute(:conditions, v)
      end
    end

    # Returns time as string with Liquid expression or Proc.
    def conditions
      @conditions_proc || MailyHerald.conditions_procs[self.id] || read_attribute(:conditions)
    end

    def has_conditions_proc?
      @conditions_proc || MailyHerald.conditions_procs[self.id]
    end

    def conditions_changed?
      if has_conditions_proc?
        @conditions_proc != MailyHerald.conditions_procs[self.id]
      else
        super
      end
    end

    def general_scheduling?
      self.start_at.is_a?(String) && Time.parse(self.start_at).is_a?(Time)
    rescue
      false
    end

    def individual_scheduling?
      !general_scheduling?
    end

    def ad_hoc?
      self.class == AdHocMailing
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

    def delivered_percentage
      (self.logs.delivered.count.to_f / self.logs.count.to_f) * 100.0
    end

    def error_percentage
      (self.logs.error.count.to_f / self.logs.count.to_f) * 100.0
    end

    def skipped_percentage
      (self.logs.skipped.count.to_f / self.logs.count.to_f) * 100.0
    end

    def scheduled_percentage
      (self.logs.scheduled.count.to_f / self.logs.count.to_f) * 100.0
    end

    def opened_percentage
      (self.logs.opened.count.to_f / self.logs.count.to_f) * 100.0
    end

    def mailer_name
      read_attribute(:mailer_name).to_sym
    end

    # Returns {Mailer} class used by this Mailing.
    def mailer
      if generic_mailer?
        MailyHerald::Mailer
      else
        self.mailer_name.to_s.constantize
      end
    end

    # Checks whether Mailing uses generic mailer.
    def generic_mailer?
      self.mailer_name == :generic
    end

    # Checks whether Mailig has conditions defined.
    def has_conditions?
      self.conditions && (has_conditions_proc? || !self.conditions.empty?)
    end

    # Checks whether entity meets conditions of this Mailing.
    #
    # @raise [ArgumentError] if the conditions do not evaluate to boolean.
    def conditions_met? entity
      subscription = Subscription.get_from(entity) || self.list.subscription_for(entity)

      if has_conditions_proc?
        !!conditions.call(entity, subscription)
      else
        if self.list.context.attributes
          evaluator = Utils::MarkupEvaluator.new(self.list.context.drop_for(entity, subscription))
          evaluator.evaluate_conditions(self.conditions)
        else
          true
        end
      end
    end

    # Checks whether conditions evaluate properly for given entity.
    def test_conditions entity
      conditions_met?(entity)
      true
    rescue StandardError => e
      false
    end

    # Returns destination email address for given entity.
    def destination entity
      self.list.context.destination_for(entity)
    end

    # Returns corresponding 'MailyHerald::Mailing::Template' object.
    def template
      @template ||= MailyHerald::Mailing::Template.new(self)
    end

    # Returns corresponding 'MailyHerald::Mailing::Renderer' object.
    def render object
      MailyHerald::Mailing::Renderer.new(self, object)
    end

    # Builds `Mail::Message` object for given entity.
    #
    # Depending on {#mailer_name} value it uses either generic mailer (from {Mailer} class)
    # or custom mailer.
    def build_mail entity
      if generic_mailer?
        Mailer.generic(entity, self)
      else
        self.mailer.send(self.name, entity)
      end
    end

    protected

    # Sends mailing to given entity.
    #
    # Performs actual sending of emails; should be called in background.
    #
    # Returns `Mail::Message`.
    def deliver schedule
      build_mail(schedule).deliver
    rescue StandardError => e
      MailyHerald.logger.log_processing(self, schedule.entity, prefix: "Error", level: :error)
      schedule.error("#{e.to_s}\n\n#{e.backtrace.join("\n")}")
      schedule.save

      MailyHerald.raise_delivery_errors? ? raise : (return nil)
    end

    # Called from Mailer, block required
    def deliver_with_mailer schedule
      entity = schedule.entity

      unless processable?(entity)
        # Most likely the entity went out of the context scope.
        # Let's leave the log for now just in case it comes back into the scope.
        MailyHerald.logger.log_processing(self, entity, prefix: "Not processable. Delaying schedule by one day", level: :debug)
        skip_reason = in_scope?(entity) ? :not_processable : :not_in_scope
        schedule.skip(skip_reason) unless schedule.postpone_delivery
        return schedule
      end

      unless conditions_met?(entity)
        MailyHerald.logger.log_processing(self, entity, prefix: "Conditions not met", level: :debug)
        schedule.skip(:conditions_unmet)
        return schedule
      end

      mail = yield # Let mailer do his job

      MailyHerald.logger.log_processing(self, entity, mail, prefix: "Processed")
      schedule.entity_email = mail.to.first # store current delivery email in case it changed since the schedule was created
      schedule.deliver({
        content: mail.to_s
      })

      return schedule
    rescue StandardError => e
      MailyHerald.logger.log_processing(self, schedule.entity, prefix: "Error", level: :error)
      schedule.error("#{e.to_s}\n\n#{e.backtrace.join("\n")}")

      MailyHerald.raise_delivery_errors? ? raise : (return schedule)
    end

    private

    def template_syntax
      validate_template :template_plain if self.mixed? || self.plain?
      validate_template :template_html  if self.mixed? || self.html?
    end

    def validate_template template_kind
      Liquid::Template.parse(self.send(template_kind))
    rescue StandardError => e
      errors.add(template_kind, e.to_s)
    end

    def validate_conditions
      return true if has_conditions_proc?

      result = Utils::MarkupEvaluator.test_conditions(self.conditions)

      errors.add(:conditions, "is not a boolean value") unless result
    rescue StandardError => e
      errors.add(:conditions, e.to_s)
    end

    def mailer_validity
      !!mailer unless generic_mailer?
    rescue
      errors.add(:mailer_name, :invalid)
    end
  end
end
