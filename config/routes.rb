MailyHerald::Engine.routes.draw do
	match 'webui', :to => 'webui#index', :via => :get
	match "sinatra", :to => MailyHerald::Webui::App, :anchor => false
  get ":token", :to => "tokens#get", :as => :token
	namespace :webui do
		resources "sequences" do
			resources "mailings", :only => [:new, :create], :controller => "mailings", :mailing_type => :sequence
			member do
				get "subscription/:entity_id", :to => :subscription, :as => :subscription
				get "subscription/:entity_id/toggle", :to => :toggle_subscription, :as => :toggle_subscription
				get "toggle", :to => :toggle, :as => :toggle
			end
		end
		resources "mailings", :except => [:new, :create] do
			member do
				get "subscription/:entity_id", :to => :subscription, :as => :subscription
				get "subscription/:entity_id/toggle", :to => :toggle_subscription, :as => :toggle_subscription
				get "dashboard/:entity_id", :to => :dashboard, :as => :dashboard
				get "deliver/(:entity_id)", :to => :deliver, :as => :deliver
				get "toggle", :to => :toggle, :as => :toggle
				get "preview/:subscription_id", :to => :preview, :as => :preview
			end
			collection do
				get "context_attributes/(:context_name)", :to => :context_attributes, :as => :context_attributes
			end
		end
		resources "sequences_mailings", :only => [:index, :new], :controller => "mailings", :mailing_type => :sequence
		resources "one_time_mailings", :only => [:index, :new, :create], :controller => "mailings", :mailing_type => :one_time
		resources "periodical_mailings", :only => [:index, :new, :create], :controller => "mailings", :mailing_type => :periodical
		resources "subscription_groups" do
			member do
				get "subscription/:subscription_id/toggle", :to => :toggle_subscription, :as => :toggle_subscription
			end
		end
		resources "dashboard", :only => [:index, :show] do
			collection do 
				get "time_travel"
				get "forget"
			end
		end
	end
end
