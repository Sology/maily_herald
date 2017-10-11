module MailyHerald
  class TokensController < MailyHerald::ApplicationController
    before_action :load_subscription

    def get
      @subscription.try(:deactivate!)

      redirect_to MailyHerald.token_redirect.try(:call, self, @subscription) || "/", notice: redirection_notice
    end

    private

    def load_subscription
      @subscription = MailyHerald::Subscription.find_by_token(params[:token])
    end

    def redirection_notice
      @subscription ? t('maily_herald.subscription.deactivated') : t('maily_herald.subscription.undefined_token')
    end
  end
end
