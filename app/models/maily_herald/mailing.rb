module MailyHerald
  class Mailing < ActiveRecord::Base
    attr_accessible :name, :context_name, :sequence, :conditions, :title, :from, :delay, :template

    belongs_to  :sequence,      :class_name => "MailyHerald::Sequence"
    has_many    :records,       :class_name => "MailyHerald::MailingRecord"
    
    validates   :context_name,  :presence => true, :if => lambda {|mailing| !mailing.sequence}
    validates   :trigger,       :presence => true, :inclusion => {:in => [:manual, :create, :save, :update, :destroy]}
    validates   :name,          :presence => true, :format => {:with => /^\w+$/}, :uniqueness => true
    validates   :title,         :presence => true
    validates   :template,      :presence => true

    def has_conditions?
      conditions && !conditions.empty?
    end

    def context
      @context ||= MailyHerald.context sequence ? sequence.context_name : context_name
    end

    def trigger
      read_attribute(:trigger).to_sym
    end
    def trigger=(value)
      write_attribute(:trigger, value.to_s)
    end

    def evaluate_conditions_for entity
      if has_conditions?
        condition = create_liquid_condition conditions
        template = Liquid::Template.parse(conditions)
        drop = @context.drop_for entity 

        liquid_context = Liquid::Context.new([drop, template.assigns], template.instance_assigns, template.registers, true, {})
        drop.context = liquid_context

        begin
          condition.evaluate liquid_context
        rescue
          false
        end
      else
        true
      end
    end

    def destination_for entity
      context.destination.call(entity)
    end

    def record_for entity
      self.records.for_entity(entity).first
    end

    def prepare_for entity
      drop = self.context.drop_for entity 
      template = Liquid::Template.parse(template)
      template.render drop
    end

    def find_or_initialize_record_for entity
      record = self.record_for(entity)
      unless record
        record = self.records.build
        record.entity = entity
      end
      record
    end

    def deliver_to entity
      if self.mailer_name == 'generic'
        # TODO make it atomic
        Mailer.generic(self.destination_for(entity), prepare_for(entity)).deliver

        # Do not save records for mailings within sequence
        unless self.sequence
          record = find_or_initialize_record_for(entity)
          record.delivered_at = DateTime.now
          record.status = "ok"
          record.save
        end
      else
        # TODO
      end
    end

    def deliver_to_all
      self.context.scope.each do |entity|
        deliver_to entity
      end
    end

    private

    def create_liquid_condition markup
      expressions = markup.scan(Liquid::If::ExpressionsAndOperators).reverse
      raise(Liquid::SyntaxError, Liquid::SyntaxHelp) unless expressions.shift =~ Liquid::If::Syntax

      condition = Liquid::Condition.new($1, $2, $3)
      while not expressions.empty?
        operator = (expressions.shift).to_s.strip

        raise(Liquid::SyntaxError, Liquid::SyntaxHelp) unless expressions.shift.to_s =~ Liquid::If::Syntax

        new_condition = Liquid::Condition.new($1, $2, $3)
        new_condition.send(operator.to_sym, condition)
        condition = new_condition
      end

      condition
    end
  end
end
