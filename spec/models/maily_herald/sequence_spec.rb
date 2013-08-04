require 'spec_helper'

describe MailyHerald::Sequence do
  before(:each) do
    @sequence = MailyHerald.sequence(:newsletters)
    @sequence.should be_a MailyHerald::Sequence
    @sequence.should_not be_a_new_record
  end

  after do
    Timecop.return
  end

  describe "Validations" do
    it {should validate_presence_of(:context_name)}
    it {should validate_presence_of(:name)}
  end


  describe "Associations" do
    it {should have_many(:subscriptions)}
    it {should have_many(:mailings)}

    it "should have valid 'through' associations" do
      @sequence.mailings.length.should_not be_zero
    end
  end

  describe "Subscriptions" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    it "should find or initialize sequence subscription" do
      subscription = @sequence.subscription_for @entity
      subscription.should be_valid
      subscription.should_not be_a_new_record
    end
  end

  describe "markup evaluation" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    it "should parse start_var" do
      @entity.should be_a(User)
      subscription = @sequence.subscription_for @entity
      subscription.next_delivery_time.should be_a(Time)
    end

    pending "should parse absolute start date"
  end

  describe "Scheduled Delivery" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    it "should deliver mailings with delays" do
      @sequence.mailings.length.should eq(2)

      subscription = @sequence.subscription_for(@entity)
      subscription.delivered_mailings.length.should eq(0)
      subscription.pending_mailings.length.should eq(2)

      Timecop.freeze @entity.created_at

      @sequence.run

      MailyHerald::MailingSubscription.count.should eq(0)
      MailyHerald::SequenceSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(0)

      Timecop.freeze @entity.created_at + @sequence.mailings.first.relative_delay + 10.minutes

      @sequence.run

      MailyHerald::MailingSubscription.count.should eq(0)
      MailyHerald::SequenceSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(1)

      subscription = @sequence.subscription_for(@entity)
      subscription.should_not be_nil
      subscription.should_not be_a_new_record
      subscription.entity.should eq(@entity)

      subscription.delivered_mailings.length.should eq(1)
      subscription.pending_mailings.length.should eq(1)
      
      subscription.last_delivered_mailing.should eq @sequence.mailings.first
      log = subscription.mailing_log_for(@sequence.mailings.first)
      log.delivered_at.to_i.should eq (@entity.created_at + 1.hour + 10.minutes).to_i

      Timecop.freeze @entity.created_at + 2.hour + 10.minutes

      @sequence.run

      MailyHerald::MailingSubscription.count.should eq(0)
      MailyHerald::SequenceSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(1)

      Timecop.freeze @entity.created_at + 3.hour + 10.minutes

      @sequence.run

      MailyHerald::MailingSubscription.count.should eq(0)
      MailyHerald::SequenceSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(2)

      subscription = @sequence.subscription_for(@entity)
      log = subscription.mailing_log_for(@sequence.mailings.first)
      log.should be_a(MailyHerald::DeliveryLog)
      log.entity.should eq(@entity)

      log = subscription.mailing_log_for(@sequence.mailings.last)
      log.should be_a(MailyHerald::DeliveryLog)
      log.entity.should eq(@entity)
    end
  end

  describe "Autosubscribe" do
    before(:each) do
      @sequence.autosubscribe = false
      @sequence.should be_valid
      @sequence.save.should be_true
      @entity = FactoryGirl.create :user
    end

    it "should not create subscription without autosubscribe" do
      subscription = @sequence.subscription_for @entity

      subscription.should be_new_record

      MailyHerald::MailingSubscription.count.should eq(0)
      MailyHerald::SequenceSubscription.count.should eq(0)
      MailyHerald::DeliveryLog.count.should eq(0)

      Timecop.freeze @entity.created_at

      @sequence.run

      MailyHerald::MailingSubscription.count.should eq(0)
      MailyHerald::SequenceSubscription.count.should eq(0)
      MailyHerald::DeliveryLog.count.should eq(0)

      @sequence.autosubscribe = true
      @sequence.save
    end
  end

end
