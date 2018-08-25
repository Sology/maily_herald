module MailyHerald
  class Mailer < ActionMailer::Base
    attr_reader :entity

    def generic entity
      mailing = @_message.maily_herald_data.mailing
      schedule = @_message.maily_herald_data.schedule

      render = mailing.render schedule || entity

      destination = mailing.destination(entity)
      subject = render.subject
      content_html = render.html if mailing.mixed? || mailing.html?
      content_plain = render.plain if mailing.mixed? || mailing.plain?

      opts = {
        to: destination, 
        subject: subject
      }
      opts[:from] = mailing.from if mailing.from.present?

      mail(opts) do |format|
        format.text { render plain: content_plain } if content_plain
        format.html { content_html } if content_html
      end
    end

    class << self
      #TODO make it instance method so we get access to instance attributes
      def deliver_mail(mail) #:nodoc:
        unless mail.maily_herald_data
          MailyHerald.logger.error("Unable to send message. Invalid mailing provided.")
          return
        end

        mailing = mail.maily_herald_data.mailing
        entity = mail.maily_herald_data.entity
        schedule = mail.maily_herald_data.schedule

        if !schedule && mailing.respond_to?(:schedule_delivery_to)
          # Implicitly create schedule for ad hoc delivery when called using Mailer.foo(entity).deliver syntax
          schedule = mail.maily_herald_data.schedule = mailing.schedule_delivery_to(entity)
        end

        if schedule
          mailing.send(:deliver_with_mailer, schedule) do
            ActiveSupport::Notifications.instrument("deliver.action_mailer") do |payload|
              set_payload_for_mail(payload, mail)
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
        @maily = @_message.maily_herald_data
      end

      super(headers).tap do |msg|
        MailyHerald::Tracking::Processor.new(msg, @_message.maily_herald_data.schedule).process if @_message.maily_herald_data
      end
    end

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
        schedule = args[1]
        mailing = schedule.mailing
        entity = schedule.entity
      else
        # Here we are in case of implicit AdHocMailing scheduling
        mailing = args[0].to_s == "generic" ? args[2] : MailyHerald.dispatch(args[0])
        entity = args[1]
      end

      @_message.maily_herald_data = Struct.new(:schedule, :mailing, :entity, :subscription).new(
        schedule,
        mailing,
        entity,
        mailing.subscription_for(entity)
      )

      if Rails::VERSION::MAJOR == 5
        lookup_context.locale = nil
      else
        lookup_context.skip_default_locale!
      end

      super(args[0], entity)

      if mailing
        @_message.to = mailing.destination(entity) unless @_message.to
        @_message.from = mailing.from unless @_message.from
      end

      @_message
    end
  end
end
