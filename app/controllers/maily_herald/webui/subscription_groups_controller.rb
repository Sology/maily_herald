module MailyHerald
	class Webui::SubscriptionGroupsController < MailyHerald::WebuiController
		before_filter :find_subscription_group, :except => [:index, :new, :create]

		def show
			subs = @subscription_group.aggregated_subscriptions
			subs = subs.select{|s| s.entity.to_s.downcase.include?(params[:filter].downcase)} if params[:filter]

			@subscriptions = smart_listing_create(:subscriptions, subs, :array => true, :partial => "maily_herald/webui/subscription_groups/subscription_list")
		end

		def new
			@subscription_group = MailyHerald::SubscriptionGroup.new
		end

		def create
			@subscription_group = MailyHerald::SubscriptionGroup.new params[:subscription_group]
			if @subscription_group.save
				redirect_to webui_subscription_group_path(:id => @subscription_group)
			else
				render :action => :new
			end
		end

		def edit
		end

		def update
			if @subscription_group.update_attributes params[:subscription_group]
				redirect_to webui_subscription_group_path(:id => @subscription_group)
			else
				render :action => :edit
			end
		end

		def destroy
			@subscription_group.destroy
			redirect_to webui_mailings_path
		end

		def toggle_subscription
			@subscription = MailyHerald::AggregatedSubscription.find params[:subscription_id]
			@subscription.toggle!
			redirect_to webui_subscription_group_path(:id => @subscription_group)
		end

		private

		def find_subscription_group
			@subscription_group = MailyHerald::SubscriptionGroup.find(params[:id])
		end
	end
end
