module MailyHerald
	class Worker
		def initialize mailing
			@mailing = mailing
			@context = MailyHerald.context @mailing.context
		end

		def prepare_for item
			output = @context.for item do |item, drop|
				template = Liquid::Template.parse(@mailing.template)
				template.render drop
			end
		end
	end
end
