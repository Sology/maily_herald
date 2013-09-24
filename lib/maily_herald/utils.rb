module MailyHerald
  module Utils
    def self.random_hex(n)
      SecureRandom.hex(n)
    end

    class MarkupEvaluator
      class DummyDrop < Liquid::Drop
        def has_key?(name)
          true
        end

        def invoke_drop name
          true
        end

        alias :[] :invoke_drop
      end

      def self.test_conditions conditions
        return true if !conditions || conditions.empty?

        condition = self.create_liquid_condition conditions
        template = Liquid::Template.parse(conditions)
        raise StandardError unless template.errors.empty?

        drop = DummyDrop.new
        liquid_context = Liquid::Context.new([drop, template.assigns], template.instance_assigns, template.registers, true, {})
        drop.context = liquid_context

        condition.evaluate liquid_context
      end


      def initialize drop
        @drop = drop
      end

      def evaluate_conditions conditions
        return true if !conditions || conditions.empty?

        condition = MarkupEvaluator.create_liquid_condition conditions
        template = Liquid::Template.parse(conditions)

        liquid_context = Liquid::Context.new([@drop, template.assigns], template.instance_assigns, template.registers, true, {})
        @drop.context = liquid_context

        condition.evaluate liquid_context
      end

      def evaluate_variable markup
        template = Liquid::Template.parse(markup)

        liquid_context = Liquid::Context.new([@drop, template.assigns], template.instance_assigns, template.registers, true, {})
        @drop.context = liquid_context
        liquid_context[markup]
      end

      private

      def self.create_liquid_condition markup
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
end
