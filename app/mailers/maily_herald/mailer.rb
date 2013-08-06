module MailyHerald
  class Mailer < ActionMailer::Base
    def generic mailing, entity, subscription
      destination = subscription.destination
      subject = mailing.title
      from = mailing.sender
      content = subscription.is_a?(SequenceSubscription) ? subscription.render_template(mailing) : subscription.render_template

      mail(to: destination, from: from, subject: subject) do |format|
        format.text { render text: content }
      end
    end
  end
end
