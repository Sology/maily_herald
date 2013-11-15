module MailyHerald
  class WebuiController < MailyHerald::ApplicationController
		include SmartListHelper::ControllerExtensions

		helper :maily_herald

		layout 'maily_herald/application'

		before_filter :prepare_data

		def index
		end

		private

		def prepare_data
			@wide = true
			
			@one_time_mailings = MailyHerald::OneTimeMailing.scoped
			@periodical_mailings = MailyHerald::PeriodicalMailing.scoped
			@sequences = MailyHerald::Sequence.scoped
			@subscription_groups = MailyHerald::SubscriptionGroup.scoped
		end
  end
end
