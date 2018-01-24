MailyHerald::Engine.routes.draw do
  get "tokens/:token/unsubscribe", to: "tokens#unsubscribe", as: :token_unsubscribe
  get "tokens/:token/open",        to: "tokens#open",        as: :token_open,         format: :gif
  get "tokens/:token/preview",     to: "tokens#preview",     as: :web_preview
end

MailyHerald::Engine.routes.url_helpers.class.module_eval do
  def maily_unsubscribe_url(subscription, *args)
    options = args.extract_options! || {}
    options = options.reverse_merge(
      {controller: "/maily_herald/tokens", action: "unsubscribe", token: subscription.token}.
      merge(Rails.application.routes.default_url_options).
      merge(Rails.application.config.action_mailer.default_url_options)
    )

    MailyHerald::Engine.routes.url_helpers.url_for(options)
  end

  def maily_open_url(token, *args)
    options = args.extract_options! || {}
    options = options.reverse_merge(
      {controller: "/maily_herald/tokens", action: "open", token: token, format: "gif"}.
      merge(Rails.application.routes.default_url_options).
      merge(Rails.application.config.action_mailer.default_url_options)
    )

    MailyHerald::Engine.routes.url_helpers.url_for(options)
  end

  def maily_web_preview_url(token, *args)
    options = args.extract_options! || {}
    options = options.reverse_merge(
      {controller: "/maily_herald/tokens", action: "preview", token: token}.
      merge(Rails.application.routes.default_url_options).
      merge(Rails.application.config.action_mailer.default_url_options)
    )

    MailyHerald::Engine.routes.url_helpers.url_for(options)
  end
end
