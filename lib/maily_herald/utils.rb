module MailyHerald
  module Utils
    def self.random_hex(n)
      SecureRandom.hex(n)
    end

    class MarkupEvaluator
      def initialize drop
        @drop = drop
      end

      def evaluate_conditions conditions
        condition = create_liquid_condition conditions
        template = Liquid::Template.parse(conditions)

        liquid_context = Liquid::Context.new([@drop, template.assigns], template.instance_assigns, template.registers, true, {})
        @drop.context = liquid_context

        begin
          condition.evaluate liquid_context
        rescue
          false
        end
      end

      def evaluate_variable markup
        template = Liquid::Template.parse(markup)

        liquid_context = Liquid::Context.new([@drop, template.assigns], template.instance_assigns, template.registers, true, {})
        @drop.context = liquid_context
        liquid_context[markup]
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
end
