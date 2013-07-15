module MailyHerald
	class Manager
		def self.handle_trigger type, entity
			mailings = Mailing.where(:trigger => type)
			mailings.each do |mailing|
				worker = Worker.new mailing
				worker.deliver_to entity
			end
		end
	end
end
