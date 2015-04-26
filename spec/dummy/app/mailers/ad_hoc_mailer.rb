class AdHocMailer < MailyHerald::Mailer
  default from: "no-reply@flossmarket.com"

  def ad_hoc_mail user
    mail to: user.email, subject: "Test"
  end
end
