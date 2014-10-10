MailyHerald::Engine.routes.draw do
  get ":token", to: "tokens#get", as: :token
end
