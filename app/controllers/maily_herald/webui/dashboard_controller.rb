module MailyHerald
	class Webui::DashboardController < MailyHerald::WebuiController
		def show
			@log = MailyHerald::Log.find params[:id]
			@entity = @log.entity
			@mailing = @log.mailing
			@sequence = @mailing.sequence if @mailing.sequence?
			@subscription = @mailing.subscription_for(@entity)
		end

		def time_travel
			head :forbidden if Rails.env.production?

			MailyHerald.simulate

			flash[:success] = "Fasten your seatbelts, time travelling in progress!"
			redirect_to webui_mailings_path
		end

		def forget
			head :forbidden if Rails.env.production?

			MailyHerald::Subscription.destroy_all
			MailyHerald::Log.destroy_all

			flash[:success] = "Can't remember nothing!"
			redirect_to webui_mailings_path
		end
	end
end
