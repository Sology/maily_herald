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
      end

      def generate_plain
        temp = template_html
                 .strip
                 .gsub(/<\/[b-z]{1,}>/, "\n")
                 .gsub(/\s{3,}/, "\n")

        ActionController::Base.helpers.strip_tags(temp).gsub(/\n{2,}/, "\n")
      end
    end
  end
end
