module MailyHerald
  class Mailing
    class Template
      include ActionView::Helpers::SanitizeHelper
      attr_reader :template_plain, :template_html

      def initialize mailing
        @template_plain   =  mailing.template_plain
        @template_html    =  mailing.template_html
      end

      %w(plain html).each do |name|
        define_method(name) do
          if send("template_#{name}").blank?
            send("generate_#{name}")
          else
            send("template_#{name}")
          end
        end
      end

      private

      def generate_html
        template_plain
          .strip
          .gsub(/\n/, "<br/>")
          .gsub(/https?:\/\/[\S]+/) { |match| "<a href=#{match}>#{match}</a>" }
      rescue
        nil
      end

      def generate_plain
        sanitize(template_html, tags: %w(a), attributes: %w(href mailto)).gsub(/\r\n/, "\n").gsub(/\n{2,}/, "\n").gsub(/\n\s{2,}/, "\n")
      rescue
        nil
      end
    end
  end
end
