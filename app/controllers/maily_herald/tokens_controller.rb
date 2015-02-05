module MailyHerald
  class TokensController < MailyHerald::ApplicationController
    def get
      @subscription = MailyHerald::Subscription.find_by_token(params[:token])
      @subscription.try(:deactivate!)

      redirect_to MailyHerald.token_redirect.try(:call, self, @subscription) || "/", 
        notice: @subscription ? t('maily_herald.subscription.deactivated') : t('maily_herald.subscription.undefined_token')
    end
  end
end
