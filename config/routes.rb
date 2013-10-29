MailyHerald::Engine.routes.draw do
	match "sinatra", :to => MailyHerald::Webui::App, :anchor => false
  get ":token", :to => "tokens#get", :as => :token
end
