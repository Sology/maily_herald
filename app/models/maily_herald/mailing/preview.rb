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

      def html
        if mail.parts.any?
          mail.html_part.body.raw_source.gsub(/<img alt=\"\" id=\"tracking-pixel\" src=\".{1,}\/>/, "")
        else
          mail.body.raw_source.html_safe
        end
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
