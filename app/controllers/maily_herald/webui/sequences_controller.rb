module MailyHerald
	class Webui::SequencesController < MailyHerald::WebuiController
		before_filter :find_sequence, :except => [:index, :new, :create]

		def show
			@mailing = MailyHerald::SequenceMailing.new
			entities = @context.scope
			entities = entities.filter_by(params[:filter]) if params[:filter]

			@sequence_entities = smart_listing_create(:sequence_entities, entities, :array => true, :partial => "maily_herald/webui/sequences/entity_list")
			@sequence_mailings = smart_listing_create(:sequence_mailings, @sequence.mailings, :array => true, :partial => "maily_herald/webui/sequences/mailing_list")
		end

		def edit
		end

		def index
		end

		def new
			@sequence = MailyHerald::Sequence.new
		end

		def create
			@sequence = MailyHerald::Sequence.new params[:sequence]
			if @sequence.save
				redirect_to webui_sequence_path(:id => @sequence)
			else
				render :action => :new
			end
		end

		def update
			if @sequence.update_attributes params[:sequence]
				redirect_to webui_sequence_path(:id => @sequence)
			else
				render :action => :edit
			end
		end

		def destroy
			@sequence.destroy
			redirect_to webui_mailings_path
		end

		def toggle
			@sequence.update_attribute :enabled, !@sequence.enabled? 
			redirect_to webui_sequence_path(:id => @sequence)
		end

		def toggle_subscription
			@subscription = @sequence.subscription_for @entity
			@subscription.toggle!
			redirect_to subscription_webui_sequence_path
		end


		def subscription
			@subscription = @sequence.subscription_for @entity
			@processed_mailings = smart_listing_create(:processed_mailings, @subscription.processed_mailings, :array => true, :partial => "/webui/sequences/mailing_list")
			@pending_mailings = smart_listing_create(:pending_mailings, @subscription.pending_mailings, :array => true, :partial => "/webui/sequences/mailing_list")
			@logs = smart_listing_create(:logs, @subscription.logs, :array => true, :partial => "/webui/mailings/log_list")
		end

		private

		def find_sequence
			@sequence = MailyHerald::Sequence.find(params[:id])
			@context = @sequence.context
			@entity = @context.model.find params[:entity_id] if params[:entity_id]
		end
	end
end
