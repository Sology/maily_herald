module MailyHerald
  # This helper helps overwriting Maily TokensController and/or views in main app
  module TokensHelper
    extend ActiveSupport::Concern

    # Cover *_url and *_path generated methods
    def method_missing(method, *args, &block)
      method.to_s.end_with?("_url", "_path") ? main_app.send(method, *args, &block) : (raise NoMethodError)
    rescue NoMethodError
      super
    end

    included do
      delegate :url_for, to: :main_app
    end
  end
end
