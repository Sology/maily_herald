class ApplicationMailer < MailyHerald::Mailer
  default from: "no-reply@mailyherald.org"
  layout 'mailer'
end
