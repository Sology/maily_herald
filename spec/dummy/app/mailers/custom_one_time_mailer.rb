class CustomOneTimeMailer < MailyHerald::Mailer
  default from: "no-reply@flossmarket.com"

  def one_time_mail user
    mail to: user.email, subject: "Test"
  end
end
