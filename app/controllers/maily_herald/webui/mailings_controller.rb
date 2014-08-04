module MailyHerald
	class Webui::MailingsController < MailyHerald::WebuiController


		before_filter :find_mailing, :except => [:index, :new, :create, :context_attributes]
		before_filter :determine_mailing_type, :only => [:index, :new, :create]

		def index
			if @klass.nil?
				redirect_to webui_dashboard_index_path
			else
				@mailing = @klass.new
				#@logs = smart_listing_create(:logs, MailyHerald::Log.unscoped.order("processed_at desc"), :partial => "/webui/mailings/log_list")
				@last_deliveries = {
					:hour => MailyHerald::Log.unscoped.order("processed_at desc").where("processed_at > (?)", Time.now - 1.hour).count,
					:day => MailyHerald::Log.unscoped.order("processed_at desc").where("processed_at > (?)", Time.now - 1.day).count,
					:week => MailyHerald::Log.unscoped.order("processed_at desc").where("processed_at > (?)", Time.now - 1.week).count,
				}
			end
		end

		def show
			entities = @context.scope
		  entities = entities.filter_by(params[:filter]) if params[:filter]

			@entities = smart_listing_create(:entities, entities, :array => true, :partial => "maily_herald/webui/mailings/entity_list")
		end

		def new
			@mailing = @klass.new
			@sequence = MailyHerald::Sequence.find params[:sequence_id] if params[:sequence_id]
			@mailing.sequence = @sequence if @sequence
		end
		
		def create
			@mailing = @klass.new params[:mailing]
			@sequence = MailyHerald::Sequence.find params[:sequence_id] if params[:sequence_id]
			@mailing.sequence = @sequence if @sequence
			if @mailing.save
				redirect_to webui_mailing_path(:id => @mailing)
			else
				puts @mailing.errors.to_yaml
				render :action => :new
			end
		end

		def edit
		end

		def update
			if @mailing.update_attributes params[:mailing]
				redirect_to webui_mailing_path(:id => @mailing)
			else
				render :action => :edit
			end
		end

		def destroy
			@mailing.destroy
			if @sequence
				redirect_to webui_sequence_path(@sequence)
			elsif	@mailing.periodical?
				redirect_to webui_periodical_mailings_path
			elsif @mailing.one_time?
				redirect_to webui_one_time_mailings_path
			end
		end

		def preview_template
			user = User.find params[:user_id]

			worker = MailyHerald::Worker.new(@mailing)

			render :text => worker.prepare_for(user)
		rescue
			render :text => 'no such user'
		end

		def subscription
			@subscription = @mailing.subscription_for @entity
			@logs = smart_listing_create(:logs, @subscription.logs, :array => true, :partial => "/webui/mailings/logs")
		end

		def deliver
			if @mailing && @entity
				MailyHerald.deliver @mailing, @entity
				redirect_to subscription_webui_mailing_path(:id => @mailing, :entity_id => @entity), :notice => 'Message delivery scheduled'
			elsif @mailing && @mailing.one_time?
				MailyHerald.run_mailing @mailing
				redirect_to webui_mailing_path(:id => @mailing), :notice => 'Message delivery scheduled'
			else
				redirect_to webui_mailing_path(:id => @mailing)
			end
		end

		def toggle
			@mailing.update_attribute :enabled, !@mailing.enabled? 
			redirect_to webui_mailing_path(:id => @mailing)
		end

		def toggle_subscription
			@subscription = @mailing.subscription_for @entity
			@subscription.toggle!
			redirect_to subscription_webui_mailing_path
		end

		def position
			case params[:change]
			when "up"
				@mailing.move_higher
			when "down"
				@mailing.move_lower
			end

			@sequence_mailings = smart_listing_create(:sequence_mailings, @sequence.mailings, :array => true, :partial => "/webui/sequences/mailing_list")

			respond_to do |format|
				format.js {render "refresh_list"} 
			end
		end

		def context_attributes
			@context = MailyHerald.context params[:context_name]
			render :layout => false
		end

		def preview
			@subscription = MailyHerald::Subscription.find params[:subscription_id]
			if @mailing.sequence?
				@template = @subscription.render_template @mailing
			else
				@template = @subscription.render_template
			end
		end

		private

		def find_mailing
			@mailing = MailyHerald::Mailing.find(params[:id])
			@sequence = @mailing.sequence if @mailing.respond_to? :sequence
			@context = @mailing.context
			@entity = @context.model.find params[:entity_id] if params[:entity_id]
		end

		def determine_mailing_type
			case params[:mailing_type]
			when :one_time
				@klass = MailyHerald::OneTimeMailing
			when :periodical
				@klass = MailyHerald::PeriodicalMailing
			when :sequence
				@klass = MailyHerald::SequenceMailing
			else
				@klass = nil
			end
		end
	end
end
