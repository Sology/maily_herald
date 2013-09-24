module MailyHerald
  #module ConditionEvaluator
    #class DummyDrop < Liquid::Drop
      #def has_key?(name)
        #true
      #end

      #def invoke_drop name
        #true
      #end

      #alias :[] :invoke_drop
    #end

    #def self.included(base)
      #base.validate :validate_conditions

      #base.send :include, MailyHerald::ConditionEvaluator::InstanceMethods
    #end

    #module InstanceMethods
      #def has_conditions?
        #self.conditions && !self.conditions.empty?
      #end

      #def evaluate_conditions_for entity
        #if has_conditions?
          #condition = create_liquid_condition self.conditions
          #template = Liquid::Template.parse(self.conditions)
          #drop = context.drop_for entity, subscription_for(entity)

          #liquid_context = Liquid::Context.new([drop, template.assigns], template.instance_assigns, template.registers, true, {})
          #drop.context = liquid_context

          #condition.evaluate liquid_context
        #else
          #true
        #end
      #end

      #def test_conditions
        #return true unless self.conditions

        #condition = create_liquid_condition self.conditions
        #template = Liquid::Template.parse(self.conditions)
        #return false unless template.errors.empty?

        #drop = DummyDrop.new
        #liquid_context = Liquid::Context.new([drop, template.assigns], template.instance_assigns, template.registers, true, {})
        #drop.context = liquid_context

        #condition.evaluate liquid_context
      #end

      #private

      #def create_liquid_condition markup
        #expressions = markup.scan(Liquid::If::ExpressionsAndOperators).reverse
        #raise(Liquid::SyntaxError, Liquid::SyntaxHelp) unless expressions.shift =~ Liquid::If::Syntax

        #condition = Liquid::Condition.new($1, $2, $3)
        #while not expressions.empty?
          #operator = (expressions.shift).to_s.strip

          #raise(Liquid::SyntaxError, Liquid::SyntaxHelp) unless expressions.shift.to_s =~ Liquid::If::Syntax

          #new_condition = Liquid::Condition.new($1, $2, $3)
          #new_condition.send(operator.to_sym, condition)
          #condition = new_condition
        #end

        #condition
      #end

      #def validate_conditions
        #test_conditions
      #rescue StandardError => e
        #errors.add(:conditions, e.to_s) 
      #end
    #end
  #end
end
