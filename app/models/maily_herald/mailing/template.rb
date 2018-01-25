module MailyHerald
  class Mailing
    class Template
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
        ::Rails::Html::WhiteListSanitizer.new.sanitize(template_html, tags: %w(a style title), attributes: %w(href mailto)).gsub(/<title>[.\s\S]{1,}<\/title>/, "").gsub(/<style>[.\s\S]{1,}<\/style>/, "").gsub(/\r\n/, "\n").gsub(/\n{2,}/, "\n").gsub(/\n\s{2,}/, "\n").strip
      rescue
        nil
      end
    end
  end
end
