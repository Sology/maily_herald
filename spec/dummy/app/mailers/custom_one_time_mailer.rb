class CustomOneTimeMailer < ApplicationMailer
  def one_time_mail user
    mail to: user.email, subject: "Test"
  end

  def mail_with_error user
    raise "This error comes from CustomOneTimeMailer#mail_with_error"
  end
end
