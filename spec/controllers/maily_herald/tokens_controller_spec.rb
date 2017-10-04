require 'spec_helper'

describe MailyHerald::TokensController do
  before(:each) do
    @user = FactoryGirl.create :user
    @mailing = MailyHerald.one_time_mailing :test_mailing
    @subscription = @mailing.subscription_for @user
  end

  describe "Unsubscribe action" do
    before(:each) do
      @mailing.token_action = :unsubscribe
      @mailing.save
    end

    describe "when regular subscription" do
      pending "should deactivate only one subscription" do
        get :get, token: @subscription.token, use_route: :maily_herald
        expect(response).to redirect_to("/")
        @subscription.reload

        expect(@subscription.active?).not_to be_true

        @user.maily_herald_subscriptions.each do |s|
          next unless s.target.subscription_group == @subscription.target.subscription_group
          next if s == @subscription

          expect(s.active?).to be_true
        end
      end
    end

    describe "when aggregated subscription" do
      before(:each) do
        @mailing.subscription_group = :account
        @mailing.save!
      end

      after(:each) do
        @mailing.subscription_group = nil
        @mailing.save!
      end

      pending "should deactivate subscription group" do
        get :get, token: @subscription.token, use_route: :maily_herald
        expect(response).to redirect_to("/")
        @subscription.reload

        expect(@subscription.active?).not_to be_true
        expect(@subscription.aggregate).not_to be_nil
        expect(@subscription.aggregate.active?).not_to be_true

        @user.maily_herald_subscriptions.each do |s|
          next unless s.target.subscription_group == @subscription.target.subscription_group

          expect(s.active?).to be_false
        end
      end
    end
  end

  pending "Custom action" do
    before(:each) do
      @mailing.token_action = :custom
      expect(@mailing).to be_valid
      @mailing.save
      expect(@mailing.token_custom_action).not_to be_nil
    end

    pending "should perform custom action" do
      @subscription.reload
      expect(@subscription.target.token_action).to eq(:custom)
      get :get, token: @subscription.token, use_route: :maily_herald
      expect(response).to redirect_to("/custom")
      @subscription.reload
      @user.reload

      expect(@user.name).to eq("changed")
    end
  end
end
