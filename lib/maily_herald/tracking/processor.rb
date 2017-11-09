module MailyHerald
  module Tracking
    class Processor
      attr_reader :message, :log

      def initialize message, log
        @message = message
        @log     = log
      end

      def process
        track_open
      end

      private

      def track_open
        if log && log.mailing.track
          add_pixel if message.html_part
        end
      end

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
