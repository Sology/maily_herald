module MailyHerald
  class Mailing
    class Preview
      attr_reader :mail

      def initialize mail
        @mail = mail
      end

      def html?
        mail.parts.any? && !mail.html_part.body.raw_source.blank? || mail.content_type.match(/html/)
      end

      def html options = {hide_tracking: true}
        h = if mail.parts.any?
              mail.html_part.body.decoded
            else
              mail.body.raw_source.html_safe
            end
        h = h.gsub(/<img alt=\"\" id=\"tracking-pixel\" src=\".{1,}\/>/, "") if options[:hide_tracking]
        h = h.gsub(/<a\ /, "<a target=\"_blank\"")
        h
      end

      def plain?
        mail.parts.any? && !mail.text_part.body.raw_source.blank? || mail.content_type.match(/plain/)
      end

      def plain
        mail.parts.any? ? mail.text_part.decoded : mail.body.decoded
      end
    end
  end
end
