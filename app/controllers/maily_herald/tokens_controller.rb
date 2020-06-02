module MailyHerald
  class TokensController < MailyHerald::ApplicationController
    layout "maily_herald/previews", only: :preview
    before_action :load_subscription, only: :unsubscribe
    before_action :load_log, only: [:open, :click, :preview]

    def unsubscribe
      @subscription.try(:deactivate!)

      redirect_to MailyHerald.token_redirect.try(:call, self, @subscription) || "/", notice: redirection_notice
    end

    def open
      if @log
        @log.status = :opened unless @log.status == :clicked
        @log.data[:opens] = @log.opens.add(request.remote_ip, request.user_agent)
        @log.save
      end

      send_data Base64.decode64("R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="), type: "image/gif", disposition: "inline"
    end

    def click
      dest_url = params.require(:dest_url)

      if @log
        @log.status = :clicked
        @log.data[:clicks] = @log.clicks.add(request.remote_ip, request.user_agent, dest_url)
        @log.save
      end

      redirect_to dest_url
    end

    def preview
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
