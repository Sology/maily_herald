module MailyHerald
  class TokensController < MailyHerald::ApplicationController
    before_action :load_subscription, only: :get
    before_action :load_log, only: :open

    def get
      @subscription.try(:deactivate!)

      redirect_to MailyHerald.token_redirect.try(:call, self, @subscription) || "/", notice: redirection_notice
    end

    def open
      if @log
        @log.data[:opened_at] << Time.now
        @log.data[:ip_addresses] << request.remote_ip
        @log.save
      end

      send_data Base64.decode64("R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="), type: "image/gif", disposition: "inline"
    end

    private

    def load_subscription
      @subscription = MailyHerald::Subscription.find_by_token(params[:token])
    end

    def load_log
      @log = MailyHerald::Log.find_by_token(params[:token])
    end

    def redirection_notice
      @subscription ? t('maily_herald.subscription.deactivated') : t('maily_herald.subscription.undefined_token')
    end
  end
end
