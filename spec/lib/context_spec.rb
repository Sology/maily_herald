require 'spec_helper'

describe MailyHerald::Context do
  describe "setup" do
    before(:each) do
      @user = FactoryGirl.create :user
      @mailing = MailyHerald.one_time_mailing :test_mailing
      @subscription = @mailing.subscription_for @user
      @context = @mailing.context
      @drop = @context.drop_for @user, @subscription
    end

    it "should get valid context" do
      @context.should be_a(MailyHerald::Context)
    end

    it "should resolve attributes properly" do
      @drop["user"].should be_a(MailyHerald::Context::Drop)
      @drop["user"]["name"].should eq(@user.name)
      @drop["user"]["properties"]["prop1"].should eq(@user.name[0])
    end

    it "should resolve subscription attributes properly" do
      @drop["subscription"].should be_a(MailyHerald::MailingSubscription)
    end
  end
end
