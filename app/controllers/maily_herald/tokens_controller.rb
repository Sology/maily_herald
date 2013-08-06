module MailyHerald
  class TokensController < MailyHerald::ApplicationController
    def get
      @subscription = Subscription.find_by_token(params[:token])
      if @subscription.target.token_action == :custom
        @subscription.target.token_custom_action.call(self, @subscription)
      else
        @subscription.deactivate!
        redirect_to MailyHerald.token_redirect.call(@subscription), :notice => t('subscription.deactivated')
      end
    end
  end
end
