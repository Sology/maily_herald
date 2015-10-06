MailyHerald::Engine.routes.draw do
  get ":token", to: "tokens#get", as: :token
end

MailyHerald::Engine.routes.url_helpers.class.module_eval do
  def maily_unsubscribe_url(subscription, *args)
    options = args.extract_options! || {}
    options = options.reverse_merge({controller: "/maily_herald/tokens", action: "get", token: subscription.token}.merge(Rails.application.routes.default_url_options))

    MailyHerald::Engine.routes.url_helpers.url_for(options)
  end
end
