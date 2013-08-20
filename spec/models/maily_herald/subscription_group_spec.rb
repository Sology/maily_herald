require 'spec_helper'

describe MailyHerald::SubscriptionGroup do
  before(:each) do
    @sequence = MailyHerald.sequence(:newsletters)
    @group = MailyHerald.subscription_group(:marketing)
    @entity = FactoryGirl.create :user
  end

  describe "Associations" do
    it {should have_many(:mailings)}
    it {should have_many(:sequences)}
    it {should have_many(:aggregated_subscriptions)}

    it "should have correct associations" do
      @sequence.subscription_group.should eq(@group)
      @group.sequences.should include(@sequence)
    end
  end

  describe "Subscribe & unsubscribe" do
    it "should handle group subscriptions" do
      MailyHerald::SequenceSubscription.count.should eq(0)
      MailyHerald::AggregatedSubscription.count.should eq(0)

      subscription = @sequence.subscription_for @entity
      subscription.should be_valid
      subscription.should_not be_a_new_record

      MailyHerald::SequenceSubscription.count.should eq(1)
      MailyHerald::AggregatedSubscription.count.should eq(1)

      subscription.aggregated?.should be_true
      aggregated = subscription.aggregate
      aggregated.should be_a(MailyHerald::AggregatedSubscription)
      aggregated.entity.should eq(@entity)
      aggregated.group.should eq(@sequence.subscription_group)

      @sequence.reload
      subscription = @sequence.subscription_for @entity
      MailyHerald::SequenceSubscription.count.should eq(1)
      MailyHerald::AggregatedSubscription.count.should eq(1)
    end
  end
  
end
