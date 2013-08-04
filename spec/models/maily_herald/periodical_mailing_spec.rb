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

  describe "Markup evaluation" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    it "should parse start_var" do
      @entity.should be_a(User)
      subscription = @mailing.subscription_for @entity
      subscription.next_delivery_time.should be_a(Time)
    end

    pending "should parse absolute start date"
  end

  describe "Periodical Delivery" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    it "should deliver mailings periodically" do
      @mailing.period.should eq 7.days

      subscription = @mailing.subscription_for @entity
      subscription.last_delivery_time.should eq nil
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
      subscription.next_delivery_time.should eq(@entity.created_at + period)
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
