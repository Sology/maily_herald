class CustomOneTimeMailer < MailyHerald::Mailer
  default from: "no-reply@mailyherald.org"

  def one_time_mail user
    mail to: user.email, subject: "Test"
  end
end
