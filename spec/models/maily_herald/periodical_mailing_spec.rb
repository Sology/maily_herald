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

  describe "Single subscription" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    describe "without autosubscribe" do
      before(:each) do
        @mailing.update_attribute(:autosubscribe, false)
      end

      after(:each) do
        @mailing.update_attribute(:autosubscribe, true)
      end

      it "should not be created without autosubscribe" do
        subscription = @mailing.subscription_for @entity

        subscription.should be_new_record
        subscription.should_not be_active

        MailyHerald::MailingSubscription.count.should eq(0)
        MailyHerald::DeliveryLog.count.should eq(0)

        Timecop.freeze @entity.created_at

        @mailing.run

        MailyHerald::MailingSubscription.count.should eq(0)
        MailyHerald::DeliveryLog.count.should eq(0)
      end
    end
  end

  describe "Aggregated subscription" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @mailing.subscription_group = :account
      @mailing.save!
    end

    after(:each) do
      @mailing.subscription_group = nil
      @mailing.save!
    end

    describe "with mailing autosubscribe" do
      it "should be created and active" do
        subscription = @mailing.subscription_for @entity

        subscription.should_not be_new_record
        subscription.should be_active

        aggregate = subscription.aggregate
        aggregate.should be_a(MailyHerald::AggregatedSubscription)
        aggregate.should be_active

        Timecop.freeze @entity.created_at

        @mailing.run

        MailyHerald::MailingSubscription.count.should eq(1)
        MailyHerald::DeliveryLog.count.should eq(1)
      end
    end

    describe "without mailing autosubscribe" do
      before(:each) do
        @mailing.update_attribute(:autosubscribe, false)
      end

      after(:each) do
        @mailing.update_attribute(:autosubscribe, true)
      end

      it "should be inactive after create" do
        subscription = @mailing.subscription_for @entity

        subscription.should be_new_record
        subscription.should_not be_active

        aggregate = subscription.aggregate
        aggregate.should be_a(MailyHerald::AggregatedSubscription)
        aggregate.should_not be_active

        Timecop.freeze @entity.created_at

        @mailing.run

        MailyHerald::MailingSubscription.count.should eq(0)
        MailyHerald::DeliveryLog.count.should eq(0)
      end

      it "should be able to activate" do
        subscription = @mailing.subscription_for @entity
        aggregate = subscription.aggregate

        subscription.should be_new_record
        subscription.should_not be_active

        aggregate.should be_new_record
        aggregate.should_not be_active

        subscription.activate!
        aggregate = subscription.aggregate

        subscription.should_not be_new_record
        subscription.should be_active

        aggregate.should_not be_new_record
        aggregate.should be_active
      end
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
