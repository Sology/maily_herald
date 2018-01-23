module MailyHerald
  class Mailing
    # Renders mailing templates using Liquid within the context
    # for provided entity.
    class Renderer
      attr_reader :mailing, :log
      delegate :entity, to: :log
      delegate :list, to: :mailing

      def initialize mailing, log
        @mailing = mailing
        @log = log
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
        template = Liquid::Template.parse(template)
        template.render! drop
      end

      def drop
        @drop ||= list.context.drop_for entity, subscription, log
      end

      def subscription
        @subscription ||= list.subscription_for(entity)
      end
    end
  end
end
