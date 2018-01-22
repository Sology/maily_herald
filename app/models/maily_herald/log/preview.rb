module MailyHerald
  class Log
    class Preview
      attr_reader :log

      def initialize log
        @log = log
      end

      # Build Mail object based on condition if delivery was processed successfully.
      def mail
        @mail ||= if log.delivered?
                    ::Mail.new(log.data[:content])
                  else
                    log.mailing.build_mail log
                  end
      end

      def html?
        mail.parts.any? && !mail.html_part.body.raw_source.blank?
      end

      def html
        if mail.parts.any?
          mail.html_part.body.raw_source.gsub(/<img alt=\"\" id=\"tracking-pixel\" src=\".{1,}\/>/, "")
        else
          mail.body.raw_source.html_safe
        end
      end

      def plain?
        mail.parts.any? && !mail.text_part.body.raw_source.blank? || !mail.body.raw_source.blank?
      end

      def plain
        mail.parts.any? ? mail.text_part.decoded : mail.body.decoded
      end
    end
  end
end
