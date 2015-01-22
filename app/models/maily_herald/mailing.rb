module MailyHerald
  class Mailing < Dispatch
    include MailyHerald::TemplateRenderer
    include MailyHerald::Autonaming

    if Rails::VERSION::MAJOR == 3
      attr_accessible :name, :title, :subject, :context_name, :override_subscription,
                      :sequence, :conditions, :mailer_name, :title, :from, :relative_delay, :template, :start_at, :period
    end

    has_many    :logs,          class_name: "MailyHerald::Log"
    
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

    def mailer_name
      read_attribute(:mailer_name).to_sym
    end

    def mailer
      if generic_mailer?
        MailyHerald::Mailer
      else
        self.mailer_name.to_s.constantize
      end
    end

    def has_conditions?
      self.conditions && !self.conditions.empty?
    end

    def generic_mailer?
      self.mailer_name == :generic
    end

    def conditions_met? entity
      subscription = self.list.subscription_for(entity)

      if self.list.context.attributes
        evaluator = Utils::MarkupEvaluator.new(self.list.context.drop_for(entity, subscription))
        evaluator.evaluate_conditions(self.conditions)
      else
        true
      end
    end

    def destination entity
      self.list.context.destination_for(entity)
    end

    def render_template entity
      subscription = self.list.subscription_for(entity)
      return unless subscription

      drop = self.list.context.drop_for entity, subscription
      perform_template_rendering drop, self.template
    end

    def build_mail entity
      if generic_mailer?
        Mailer.generic(entity, self)
      else
        self.mailer.send(self.name, entity)
      end
    end

    def deliver_to entity
      build_mail(entity).deliver
    end

    protected

    # Called from Mailer, block required
    def deliver_with_mailer_to entity
      unless processable?(entity)
        MailyHerald.logger.log_processing(self, entity, prefix: "Not processable", level: :debug) 
        return 
      end

      unless conditions_met?(entity)
        MailyHerald.logger.log_processing(self, entity, prefix: "Conditions not met", level: :debug) 
        return {status: :skipped}
      end

      mail = yield # Let mailer do his job

      MailyHerald.logger.log_processing(self, entity, mail, prefix: "Processed") 

      return {status: :delivered, data: {content: mail.to_s}}
    rescue StandardError => e
      MailyHerald.logger.log_processing(self, entity, prefix: "Error", level: :error) 
      return {status: :error, data: {msg: "#{e.to_s}\n\n#{e.backtrace.join("\n")}"}}
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
