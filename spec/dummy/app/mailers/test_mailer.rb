class TestMailer < MailyHerald::Mailer
  default from: "no-reply@flossmarket.com"

  def sample_mail user
    mail to: user.email, subject: "Test"
  end

  def sample_mail_error user
    mail to: user.email, subject: "Test"
  end
end
