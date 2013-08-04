module MailyHerald
  class Mailer < ActionMailer::Base
    def generic destination, content
      mail(to: destination, from: MailyHerald.default_from) do |format|
        #format.html { render text: content }
        format.text { render text: content }
      end
    end
  end
end
