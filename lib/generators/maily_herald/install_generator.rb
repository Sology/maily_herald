module MailyHerald
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc "Creates a MailyHerald initializer and copy locale files to your application."

      def copy_initializer
        template "maily_herald.rb", "config/initializers/maily_herald.rb"
      end

      def copy_locale
        copy_file "../../../config/locales/en.yml", "config/locales/maily_herald.en.yml"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
