module MailyHerald
  class Mailing < Dispatch
    include MailyHerald::TemplateRenderer

    attr_accessible :title, :subject, :context_name, :override_subscription,
                    :sequence, :conditions, :mailer_name, :title, :from, :relative_delay, :template, :start_at, :period

    has_many    :logs,          class_name: "MailyHerald::Log", dependent: :destroy
    
    validates   :title,         presence: true
    validates   :subject,       presence: true, if: :generic_mailer?
    validates   :template,      presence: true, if: :generic_mailer?
    validate    :template_syntax
    validate    :validate_conditions

    before_validation do
      write_attribute(:name, self.title.downcase.gsub(/\W/, "_")) if self.title && (!self.name || self.name.empty?)
    end

    after_initialize do
      if self.new_record?
        self.override_subscription = false
        self.mailer_name = :generic
      end
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

    def sender
      if self.from && !self.from.empty?
        self.from
      else
        MailyHerald.default_from
      end
    end

    def has_conditions?
      self.conditions && !self.conditions.empty?
    end

    def generic_mailer?
      self.mailer_name == "generic"
    end

    def conditions_met? entity
      subscription = self.list.subscription_for(entity)
      return false unless subscription

      evaluator = Utils::MarkupEvaluator.new(self.list.context.drop_for(entity, subscription))
      evaluator.evaluate_conditions(self.conditions)
    end

    def destination entity
      self.list.context.destination_attribute ? entity.send(self.list.context.destination_attribute) : self.list.context.destination.call(entity)
    end

    def render_template entity
      subscription = self.list.subscription_for(entity)
      return unless subscription

      drop = self.list.context.drop_for entity, subscription
      perform_template_rendering drop, self.template
    end

    protected

    def deliver_to entity
      if self.mailer_name == 'generic'
        subscription = self.list.subscription_for entity
        mail = Mailer.generic(entity, self)
      else
        mail = self.mailer_name.constantize.send(self.name, entity)
      end

      mail.deliver
    end

    # Called from Mailer, block required
    def deliver_with_mailer_to entity
      return unless processable?(entity)
      unless conditions_met?(entity)
        return {status: :skipped}
      end

      mail = yield # Let mailer do his job

      return {status: :delivered, data: {content: mail.to_s}}
    rescue StandardError => e
      return {status: :error, data: {msg: e.to_s}}
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
