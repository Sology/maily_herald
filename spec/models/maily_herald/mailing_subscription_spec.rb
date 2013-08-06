require 'spec_helper'

describe MailyHerald::MailingSubscription do
  describe "Associations" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @mailing = MailyHerald.one_time_mailing :test_mailing
      @subscription = @mailing.subscription_for @entity
    end

    it {should belong_to(:entity)}
    it {should belong_to(:mailing)}

    it "should have valid associations" do
      @subscription.entity.should eq(@entity)
      @subscription.mailing.should eq(@mailing)
      @subscription.should be_valid
      @subscription.should_not be_a_new_record
    end

    it "should unsubscribe" do
      @subscription.target.token_action.should eq(:unsubscribe)
      @subscription.active.should be_true
      @subscription.deactivate!
      @subscription.active.should_not be_true
    end
  end
end
