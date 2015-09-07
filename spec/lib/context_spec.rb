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
        expect(@context).to be_kind_of(MailyHerald::Context)
      end

      it "should resolve attributes properly" do
        expect(@drop["user"]).to be_kind_of(MailyHerald::Context::Drop)
        expect(@drop["user"]["name"]).to eq(@user.name)
        expect(@drop["user"]["properties"]["prop1"]).to eq(@user.name[0])
      end

      it "should resolve subscription attributes properly" do
        expect(@drop["subscription"]).to be_kind_of(MailyHerald::Subscription)
      end
    end
  end

  it "should handle both destination procs and strings" do
    @user = FactoryGirl.create :user
    context = MailyHerald.context :all_users
    expect(context.destination_for(@user)).to eq(@user.email)
    expect(context.destination_attribute).to be_nil
  end
end
