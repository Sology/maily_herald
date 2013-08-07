require 'spec_helper'

describe MailyHerald::PeriodicalMailing do
  before(:each) do
    @mailing = MailyHerald.periodical_mailing(:weekly_summary)
    @mailing.should be_a MailyHerald::PeriodicalMailing
    @mailing.should_not be_a_new_record
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
  end

  describe "Start time evaluation" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    after do
      @mailing.update_attribute(:start, nil)
    end

    it "should parse start_var" do
      @entity.should be_a(User)
      @mailing.start_var.should_not be_empty
      subscription = @mailing.subscription_for @entity
      subscription.next_delivery_time.should be_a(Time)
    end

    it "should use absolute start date if possible" do
      @entity.should be_a(User)
      time = @entity.created_at + rand(100).days + rand(24).hours + rand(60).minutes
      @mailing.update_attribute(:start, time)
      @mailing.start.should be_a(Time)
      subscription = @mailing.subscription_for @entity
      subscription.next_delivery_time.should be_a(Time)
      subscription.next_delivery_time.should eq(time)
    end
  end

  describe "Periodical Delivery" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    it "should deliver mailings periodically" do
      @mailing.period.should eq 7.days

      subscription = @mailing.subscription_for @entity
      subscription.last_delivery_time.should eq nil
      subscription.next_delivery_time.to_i.should eq((@entity.created_at).to_i)

      Timecop.freeze @entity.created_at
      @mailing.run

      subscription = @mailing.subscription_for @entity
      subscription.last_delivery_time.to_i.should eq @entity.created_at.to_i
      subscription.next_delivery_time.to_i.should eq((@entity.created_at + 7.days).to_i)
    end

    it "should deliver mailings after period" do
      subscription = @mailing.subscription_for @entity

      MailyHerald::MailingSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(0)

      Timecop.freeze @entity.created_at

      @mailing.run

      MailyHerald::MailingSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(1)

      log = MailyHerald::DeliveryLog.first
      log.entity.should eq(@entity)
      log.mailing.should eq(@mailing)

      subscription.logs.last.should eq(log)
      subscription.last_delivery_time.to_i.should eq(@entity.created_at.to_i)

      @mailing.run

      MailyHerald::MailingSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(1)

      Timecop.freeze @entity.created_at + @mailing.period + @mailing.period/3

      @mailing.run

      MailyHerald::MailingSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(2)

      Timecop.freeze @entity.created_at + @mailing.period + @mailing.period/2

      @mailing.run

      MailyHerald::MailingSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(2)
    end

    it "should calculate valid next delivery date" do
      subscription = @mailing.subscription_for @entity
      period = @mailing.period

      subscription.last_delivery_time.should be_nil
      subscription.start_delivery_time.should eq(@entity.created_at)
      subscription.next_delivery_time.should eq(@entity.created_at)
    end

  end

  describe "Error handling" do
    before do
      @old_start_var = @mailing.start_var
      @mailing.update_attribute(:start_var, "")
    end

    before(:each) do
      @entity = FactoryGirl.create :user
    end

    it "should handle start_var parsing errors or nil start time" do
      subscription = @mailing.subscription_for @entity
      subscription.last_delivery_time.should be_nil
      subscription.next_delivery_time.should be_nil

      Timecop.freeze @entity.created_at
      @mailing.run

      subscription = @mailing.subscription_for @entity
      subscription.last_delivery_time.should be_nil
      subscription.next_delivery_time.should be_nil
    end

    after do
      @mailing.update_attribute(:start_var, @old_start_var)
    end
  end

  describe "Autosubscribe" do
    before(:each) do
      @mailing.autosubscribe = false
      @mailing.should be_valid
      @mailing.save.should be_true
      @entity = FactoryGirl.create :user
    end

    it "should not create subscription without autosubscribe" do
      subscription = @mailing.subscription_for @entity

      subscription.should be_new_record

      MailyHerald::MailingSubscription.count.should eq(0)
      MailyHerald::DeliveryLog.count.should eq(0)

      Timecop.freeze @entity.created_at

      @mailing.run

      MailyHerald::MailingSubscription.count.should eq(0)
      MailyHerald::DeliveryLog.count.should eq(0)

      @mailing.autosubscribe = true
      @mailing.save
    end
  end

  describe "Subscription override" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    after do
      @mailing.update_attribute(:override_subscription, false)
    end

    it "should be able to override subscription" do
      subscription = @mailing.subscription_for @entity

      subscription.should be_active
      subscription.deactivate!
      subscription.should_not be_active

      subscription.last_delivery_time.should be_nil

      Timecop.freeze @entity.created_at

      @mailing.run

      subscription.last_delivery_time.should be_nil

      @mailing.update_attribute(:override_subscription, true)

      @mailing.run

      subscription.last_delivery_time.to_i.should eq(@entity.created_at.to_i)
    end
  end

  describe "Conditions" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    it "should check mailing conditions" do
      subscription = @mailing.subscription_for @entity

      MailyHerald::MailingSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(0)

      Timecop.freeze @entity.created_at

      @mailing.run

      MailyHerald::MailingSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(1)

      @entity.weekly_notifications = false
      @entity.save

      Timecop.freeze @entity.created_at + @mailing.period + @mailing.period/3

      @mailing.run

      MailyHerald::MailingSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(1)

      @entity.weekly_notifications = true
      @entity.save

      @mailing.run

      MailyHerald::MailingSubscription.count.should eq(1)
      MailyHerald::DeliveryLog.count.should eq(2)
    end
  end
end
