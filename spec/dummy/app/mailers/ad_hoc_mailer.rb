class AdHocMailer < ApplicationMailer
  def ad_hoc_mail user
    mail to: user.email, subject: "Test"
  end

  def missing_mailing_mail user
    mail to: user.email, subject: "Test", from: "foo@bar.com"
  end
end
