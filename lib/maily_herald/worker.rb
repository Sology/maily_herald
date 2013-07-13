module MailyHerald
	class Worker
		def initialize mailing
			@mailing = mailing
			@context = MailyHerald.context @mailing.context
		end

		def prepare_for item
			drop = @context.drop_for item 
			template = Liquid::Template.parse(@mailing.template)
			template.render drop
		end

		def evaluate_condition_for item
			condition = create_liquid_condition @mailing.condition
			template = Liquid::Template.parse(@mailing.condition)
			drop = @context.drop_for item 

			liquid_context = Liquid::Context.new([drop, template.assigns], template.instance_assigns, template.registers, true, {})
			drop.context = liquid_context

			condition.evaluate liquid_context
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
