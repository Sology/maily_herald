module MailyHerald
  class Mailing
    # Renders mailing templates using Liquid within the context
    # for provided entity.
    class Renderer
      attr_reader :mailing, :object
      delegate :list, to: :mailing

      def initialize mailing, object
        @mailing = mailing
        @object = object
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
        @drop ||= log? ? list.context.drop_for(entity, subscription, object) : list.context.drop_for(object, subscription)
      end

      def subscription
        @subscription ||= list.subscription_for entity
      end

      def entity
        @entity ||= log? ? object.entity : object
      end

      def log?
        object.is_a? ::MailyHerald::Log
      end
    end
  end
end
