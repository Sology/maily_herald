module MailyHerald
  class Mailer < ActionMailer::Base
    def generic mailing, entity
      destination = mailing.destination_for(entity)
      subject = mailing.title
      from = mailing.sender
      content = mailing.prepare_for(entity)

      mail(to: destination, from: from, subject: subject) do |format|
        format.text { render text: content }
      end
    end
  end
end
