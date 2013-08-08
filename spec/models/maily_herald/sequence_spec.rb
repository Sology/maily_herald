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

    after do
      @sequence.update_attribute(:start, nil)
    end

    it "should parse start_var" do
      @entity.should be_a(User)
      subscription = @sequence.subscription_for @entity
      subscription.next_delivery_time.should be_a(Time)
    end

    it "should use absolute start date if possible" do
      @entity.should be_a(User)
      time = @entity.created_at + rand(100).days + rand(24).hours + rand(60).minutes
      @sequence.update_attribute(:start, time)
      @sequence.start.should be_a(Time)
      subscription = @sequence.subscription_for @entity
      subscription.next_delivery_time.should be_a(Time)
      subscription.next_delivery_time.should eq(time + @sequence.mailings.first.relative_delay)
    end
  end

  describe "Scheduled Delivery" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    it "should deliver mailings with delays" do
      @sequence.mailings.length.should eq(3)

      subscription = @sequence.subscription_for(@entity)
      subscription.delivered_mailings.length.should eq(0)
      subscription.pending_mailings.length.should eq(@sequence.mailings.length)

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
      subscription.pending_mailings.length.should eq(@sequence.mailings.length - 1)
      
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

      log = subscription.mailing_log_for(@sequence.mailings[1])
      log.should be_a(MailyHerald::DeliveryLog)
      log.entity.should eq(@entity)
    end

    pending "should skip disabled mailings and go on"
  end

  describe "Error handling" do
    before do
      @old_start_var = @sequence.start_var
      @sequence.update_attribute(:start_var, "")
    end

    before(:each) do
      @entity = FactoryGirl.create :user
    end

    it "should handle start_var parsing errors or nil start time" do
      subscription = @sequence.subscription_for @entity
      subscription.last_delivery_time.should be_nil
      subscription.next_delivery_time.should be_nil

      Timecop.freeze @entity.created_at
      @sequence.run

      subscription = @sequence.subscription_for @entity
      subscription.last_delivery_time.should be_nil
      subscription.next_delivery_time.should be_nil
    end

    after do
      @sequence.update_attribute(:start_var, @old_start_var)
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

  describe "Subscription override" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    after do
      @sequence.update_attribute(:override_subscription, false)
    end

    it "should be able to override subscription" do
      subscription = @sequence.subscription_for @entity

      subscription.should be_active

      next_delivery = subscription.next_delivery_time

      subscription.deactivate!
      subscription.should_not be_active

      subscription.last_delivery_time.should be_nil

      Timecop.freeze subscription.next_delivery_time

      @sequence.run

      subscription.last_delivery_time.should be_nil


      @sequence.update_attribute(:override_subscription, true)

      @sequence.run

      subscription.last_delivery_time.to_i.should eq(next_delivery.to_i)
    end
  end

end
