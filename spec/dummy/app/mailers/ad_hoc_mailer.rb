class AdHocMailer < MailyHerald::Mailer
  default from: "no-reply@mailyherald.org"

  def ad_hoc_mail user
    mail to: user.email, subject: "Test"
  end
end
