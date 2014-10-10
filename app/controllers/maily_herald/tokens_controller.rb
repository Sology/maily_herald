module MailyHerald
  class TokensController < MailyHerald::ApplicationController
    def get
      @subscription = MailyHerald::Subscription.find_by_token(params[:token])

      if @subscription && @subscription.target.token_action == :custom
        @subscription.target.token_custom_action.call(self, @subscription)
      elsif @subscription
        @subscription.deactivate!
        redirect_to MailyHerald.token_redirect.call(@subscription), notice: t('maily_herald.subscription.deactivated')
      else
        redirect_to "/", notice: t('maily_herald.subscription.undefined_token')
      end
    end
  end
end
