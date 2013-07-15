module MailyHerald
	module ModelExtensions
		module TriggerPatch
			def self.included(base)
				base.class_eval do
					after_create :maily_herald_trigger_create
					after_save :maily_herald_trigger_save
					after_update :maily_herald_trigger_update
					after_destroy :maily_herald_trigger_destroy
				end
			end

			def maily_herald_trigger_create
				MailyHerald::Manager.handle_trigger :create, self
			end

			def maily_herald_trigger_save
				MailyHerald::Manager.handle_trigger :save, self
			end

			def maily_herald_trigger_update
				MailyHerald::Manager.handle_trigger :update, self
			end

			def maily_herald_trigger_destroy
				MailyHerald::Manager.handle_trigger :destroy, self
			end
		end
	end
end
