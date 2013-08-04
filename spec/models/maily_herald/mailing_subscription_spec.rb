require 'spec_helper'

describe MailyHerald::MailingSubscription do
  describe "Associations" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @mailing = MailyHerald.one_time_mailing :test_mailing
    end

    it {should belong_to(:entity)}
    it {should belong_to(:mailing)}

    it "should have valid associations" do
      subscription = @mailing.subscription_for @entity
      subscription.entity.should eq(@entity)
      subscription.mailing.should eq(@mailing)
      subscription.should be_valid
    end
  end
end
