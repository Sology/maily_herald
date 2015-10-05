module MailyHerald
  class Mailer < ActionMailer::Base
    attr_reader :entity

    def generic entity
      destination = @maily_herald_mailing.destination(entity)
      subject = @maily_herald_mailing.render_subject(entity)
      content = @maily_herald_mailing.render_template(entity)

      opts = {
        to: destination, 
        subject: subject
      }
      opts[:from] = @maily_herald_mailing.from if @maily_herald_mailing.from.present?

      mail(opts) do |format|
        format.text { render text: content }
      end
    end

    class << self
      #TODO make it instance method so we get access to instance attributes
      def deliver_mail(mail) #:nodoc:
        unless mail.maily_herald_data
          MailyHerald.logger.error("Unable to send message. Invalid mailing provided.")
          return
        end

        mailing = mail.maily_herald_data[:mailing]
        entity = mail.maily_herald_data[:entity]
        schedule = mail.maily_herald_data[:schedule]

        if !schedule && mailing.respond_to?(:schedule_delivery_to)
          # Implicitly create schedule for ad hoc delivery when called using Mailer.foo(entity).deliver syntax
          schedule = mail.maily_herald_data[:schedule] = mailing.schedule_delivery_to(entity)
        end

        if schedule
          mailing.send(:deliver_with_mailer, schedule) do
            ActiveSupport::Notifications.instrument("deliver.action_mailer") do |payload|
              self.set_payload_for_mail(payload, mail)
              yield # Let Mail do the delivery actions
            end
            mail
          end
        else
          MailyHerald.logger.log_processing(mailing, entity, mail, prefix: "Attempt to deliver email without schedule. No mail was sent", level: :debug)
        end
      end
    end

    def mail(headers = {}, &block)
      return @_message if @_mail_was_called && headers.blank? && !block

      # Assign instance variables availabe for template
      if @_message.maily_herald_data
        @maily_subscription = @_message.maily_herald_data[:subscription]
        @maily_entity = @_message.maily_herald_data[:entity]
        @maily_mailing = @_message.maily_herald_data[:mailing]
      end

      super
    end

    protected

    def process(*args) #:nodoc:
      class << @_message
        attr_accessor :maily_herald_data

        def maily_herald_processable?
          @maily_herald_processable ||= maily_herald_data[:mailing].processable?(maily_herald_data[:entity])
        end

        def maily_herald_conditions_met?
          @maily_herald_conditions_met ||= maily_herald_data[:mailing].conditions_met?(maily_herald_data[:entity])
        end
      end

      if args[1].is_a?(MailyHerald::Log)
        @maily_herald_schedule = args[1]
        @maily_herald_mailing = @maily_herald_schedule.mailing
        @maily_herald_entity = @maily_herald_schedule.entity
      else
        @maily_herald_mailing = args[0].to_s == "generic" ? args[2] : MailyHerald.dispatch(args[0])
        @maily_herald_entity = args[1]
      end

      if @maily_herald_mailing
        @_message.maily_herald_data = {
          schedule: @maily_herald_schedule,
          mailing: @maily_herald_mailing,
          entity: @maily_herald_entity,
          subscription: @maily_herald_mailing.subscription_for(@maily_herald_entity),
        }
      end

      lookup_context.skip_default_locale!
      super(args[0], @maily_herald_entity)

      if @maily_herald_mailing
        @_message.to = @maily_herald_mailing.destination(@maily_herald_entity) unless @_message.to
        @_message.from = @maily_herald_mailing.from unless @_message.from
      end

      @_message
    end
  end
end
