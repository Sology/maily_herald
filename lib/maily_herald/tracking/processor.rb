module MailyHerald
  module Tracking
    class Processor
      attr_reader :message, :log

      def initialize message, log
        @message = message
        @log     = log
      end

      def process
        add_pixel if log && log.mailing.track && (message.content_type.include?("text/html") || message.html_part)
        replace_links if log && log.mailing.track && (message.content_type.include?("text/html") || message.html_part)
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

      def replace_links
        raw_source = (message.html_part || message).body.raw_source
        regex = /<a\s(.*?)href="(.*?)"(.*?)>/im

        return unless raw_source.match(regex)

        raw_source.gsub!(regex) do |_match|
          pre, url, post = $1, $2, $3
          next "<a #{pre}href=\"#{url}\"#{post}>" unless url =~ /https?:\/\/[\S]+/ && url !~ /^https?:\/\/[\S]+\/unsubscribe\/tokens\/[\S]+\/unsubscribe$/
          "<a #{pre}href=\"#{url_for_click(url)}\"#{post}>"
        end
      end

      def url_for_open
        Rails.application.routes.url_helpers.maily_open_url(log.token)
      end

      def url_for_click dest_url
        Rails.application.routes.url_helpers.maily_click_url(log.token, dest_url)
      end
    end
  end
end
