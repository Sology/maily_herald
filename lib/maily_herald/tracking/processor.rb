module MailyHerald
  module Tracking
    class Processor
      attr_reader :message, :log

      def initialize message, log
        @message = message
        @log     = log
      end

      def process
        add_pixel if log && log.mailing.track && message.html_part
      end

      private

      def add_pixel
        raw_source = (message.html_part || message).body.raw_source
        regex = /<\/body>/i
        pixel = ActionController::Base.helpers.image_tag url_for_open, size: "1x1", alt: "", id: "tracking-pixel"

        if raw_source.match(regex)
          raw_source.gsub!(regex, "#{pixel}\\0")
        else
          raw_source << pixel
        end
      end

      def url_for_open
        Rails.application.routes.url_helpers.maily_open_url(log.token)
      end
    end
  end
end
