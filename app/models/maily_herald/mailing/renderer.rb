module MailyHerald
  class Mailing
    # Renders mailing templates using Liquid within the context
    # for provided entity.
    class Renderer
      attr_reader :mailing, :log, :e
      delegate :entity, to: :log, allow_nil: true
      delegate :list, to: :mailing

      def initialize mailing, log, e = nil
        @mailing = mailing
        @log = log
        @e = e
      end

      # Render html template
      def html
        perform mailing.template.html
      end

      # Render plain template
      def plain
        perform mailing.template.plain
      end

      # Render subject
      def subject
        perform mailing.subject
      end

      private

      def perform template
        template = Liquid::Template.parse template
        template.render! drop
      end

      def drop
        @drop ||= list.context.drop_for ent, subscription, log
      end

      def subscription
        @subscription ||= list.subscription_for ent
      end

      def ent
        @ent = log ? entity : e
      end
    end
  end
end
