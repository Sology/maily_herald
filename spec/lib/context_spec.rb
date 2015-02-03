require 'spec_helper'

describe MailyHerald::Context do
  describe "setup" do
    before(:each) do
      @user = FactoryGirl.create :user
      @mailing = MailyHerald.one_time_mailing :test_mailing
      @list = @mailing.list
      @context = @list.context
    end

    describe "with subscription" do
      before(:each) do
        @list.subscribe! @user
        @subscription = @mailing.subscription_for @user
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
        @drop["subscription"].should be_a(MailyHerald::Subscription)
      end
    end
  end

  it "should handle both destination procs and strings" do
    @user = FactoryGirl.create :user
    context = MailyHerald.context :all_users
    context.destination_for(@user).should eq(@user.email)
    context.destination_attribute.should be_nil
  end
end
