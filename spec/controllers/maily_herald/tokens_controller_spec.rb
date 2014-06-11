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
        get :get, :token => @subscription.token, :use_route => :maily_herald
        response.should redirect_to("/")
        @subscription.reload

        @subscription.active?.should_not be_true

        @user.maily_herald_subscriptions.each do |s|
          next unless s.target.subscription_group == @subscription.target.subscription_group
          next if s == @subscription

          s.active?.should be_true
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
        get :get, :token => @subscription.token, :use_route => :maily_herald
        response.should redirect_to("/")
        @subscription.reload

        @subscription.active?.should_not be_true
        @subscription.aggregate.should_not be_nil
        @subscription.aggregate.active?.should_not be_true

        @user.maily_herald_subscriptions.each do |s|
          next unless s.target.subscription_group == @subscription.target.subscription_group

          s.active?.should be_false
        end
      end
    end
  end

  pending "Custom action" do
    before(:each) do
      @mailing.token_action = :custom
      @mailing.should be_valid
      @mailing.save
      @mailing.token_custom_action.should_not be_nil
    end

    pending "should perform custom action" do
      @subscription.reload
      @subscription.target.token_action.should eq(:custom)
      get :get, :token => @subscription.token, :use_route => :maily_herald
      response.should redirect_to("/custom")
      @subscription.reload
      @user.reload

      @user.name.should eq("changed")
    end
  end
end
