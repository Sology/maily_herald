module MailyHerald
  class Mailer < ActionMailer::Base
    attr_reader :entity

    def generic entity, mailing
      destination = mailing.destination(entity)
      subject = mailing.subject
      from = mailing.sender
      content = mailing.render_template(entity)

      mail(to: destination, from: from, subject: subject) do |format|
        format.text { render text: content }
      end
    end

    class << self
      #TODO make it instance method so we get access to instance attributes
      def deliver_mail(mail) #:nodoc:
        mailing = mail.maily_herald_data[:mailing]
        entity = mail.maily_herald_data[:entity]

        if mailing && entity
          mailing.deliver_with_mailer_to(entity) do
            ActiveSupport::Notifications.instrument("deliver.action_mailer") do |payload|
              self.set_payload_for_mail(payload, mail)
              yield # Let Mail do the delivery actions
            end
          end
        elsif mail.raise_delivery_errors
          raise ArgumentError.new("MailyHerald: unable to find mailing and/or entity associated to this mailer action")
        end
      end
    end

    protected

    def process(*args) #:nodoc:
      class << @_message
        attr_accessor :maily_herald_data
      end

      @_message.maily_herald_data = {
        :mailing => args[0].to_s == "generic" ? args[2] : MailyHerald.dispatch(args[0]),
        :entity => args[1]
      }

      lookup_context.skip_default_locale!
      super
    end
  end
end
