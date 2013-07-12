module MailyHeraldHelper
	def maily_herald_context_options_for_select selected = nil, options = {}
		MailyHerald.contexts.keys.collect {|c| [c, c] }
	end
end
