require 'spec_helper'

describe MailyHerald::OneTimeMailing do
  before(:each) do
    @mailing = MailyHerald.one_time_mailing(:test_mailing)
    @mailing.should be_a MailyHerald::OneTimeMailing
    @mailing.should_not be_a_new_record

    @entity = FactoryGirl.create :user
  end

  it "should be delivered" do
    subscription = @mailing.subscription_for @entity

    MailyHerald::MailingSubscription.count.should eq(1)
    MailyHerald::Log.count.should eq(0)

    subscription.conditions_met?.should be_true
    subscription.processable?.should be_true

    @mailing.run

    MailyHerald::MailingSubscription.count.should eq(1)
    MailyHerald::Log.count.should eq(1)

    log = MailyHerald::Log.first
    log.entity.should eq(@entity)
    log.mailing.should eq(@mailing)
  end
end
