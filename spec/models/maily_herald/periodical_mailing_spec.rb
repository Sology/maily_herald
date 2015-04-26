require 'spec_helper'

describe MailyHerald::PeriodicalMailing do
  before(:each) do
    @mailing = MailyHerald.periodical_mailing(:weekly_summary)
    @mailing.should be_a MailyHerald::PeriodicalMailing
    @mailing.should_not be_a_new_record

    @list = @mailing.list
    @mailing.start_at.should eq("user.created_at")
  end

  after do
    Timecop.return
  end

  describe "Subscribing" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
    end

    it "should create schedule" do
      MailyHerald::Log.scheduled.for_mailing(@mailing).count.should eq(1)
    end
  end

  describe "Updating schedules" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
      @start_at = @mailing.start_at
    end

    after(:each) do
      @mailing.update_attribute(:start_at, @start_at)
      @mailing.update_attribute(:state, "enabled")
    end

    it "should be triggered by start_at change" do
      MailyHerald::Log.scheduled.for_mailing(@mailing).count.should eq(1)
      schedule = MailyHerald::Log.scheduled.for_mailing(@mailing).first
      schedule.processing_at.to_i.should eq(@entity.created_at.to_i)

      time = Time.now + 10.days
      @mailing.update_attribute(:start_at, time.to_s)

      schedule.reload
      schedule.processing_at.to_i.should eq(time.to_i)
    end

    it "should be triggered by unsubscribe" do
      MailyHerald::Log.scheduled.for_mailing(@mailing).count.should eq(1)
      schedule = MailyHerald::Log.scheduled.for_mailing(@mailing).first
      schedule.processing_at.to_i.should eq(@entity.created_at.to_i)

      @list.unsubscribe! @entity

      expect(MailyHerald::Log.scheduled.for_mailing(@mailing).first).to be_nil
    end

    it "should be triggered by disabling mailing" do
      MailyHerald::Log.scheduled.for_mailing(@mailing).count.should eq(1)
      schedule = MailyHerald::Log.scheduled.for_mailing(@mailing).first
      schedule.processing_at.to_i.should eq(@entity.created_at.to_i)

      @mailing.disable!

      expect(MailyHerald::Log.scheduled.for_mailing(@mailing).first).to be_nil

      @mailing.enable!

      expect(MailyHerald::Log.scheduled.for_mailing(@mailing).first).not_to be_nil

      @mailing.disable!

      expect(MailyHerald::Log.scheduled.for_mailing(@mailing).first).to be_nil
    end
  end

  describe "Start time evaluation" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
      @start_at = @mailing.start_at
    end

    after(:each) do
      @mailing.update_attribute(:start_at, @start_at)
    end

    it "should parse start_at" do
      @entity.should be_a(User)
      @mailing.start_processing_time(@entity).should be_a(Time)
      @mailing.next_processing_time(@entity).should be_a(Time)
      @mailing.next_processing_time(@entity).to_i.should eq(@entity.created_at.to_i)
    end

    it "should use absolute start date if possible" do
      @entity.should be_a(User)
      time = (@entity.created_at + rand(100).days + rand(24).hours + rand(60).minutes).round
      @mailing.update_attribute(:start_at, time.to_s)

      @mailing.start_processing_time(@entity).should be_a(Time)
      @mailing.next_processing_time(@entity).should be_a(Time)
      @mailing.next_processing_time(@entity).should eq(time)
    end
  end

  describe "Periodical Delivery" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
    end

    it "should deliver mailings periodically" do
      @mailing.period.should eq 7.days

      @mailing.last_processing_time(@entity).should eq nil
      @mailing.next_processing_time(@entity).to_i.should eq((@entity.created_at).to_i)

      Timecop.freeze @entity.created_at
      ret = @mailing.run
      ret.should be_a(Array)
      ret.first.should be_a(MailyHerald::Log)
      ret.first.mail.should be_a(Mail::Message)
      ret.first.should be_delivered

      @mailing.last_processing_time(@entity).to_i.should eq @entity.created_at.to_i
      @mailing.next_processing_time(@entity).to_i.should eq((@entity.created_at + 7.days).to_i)
    end

    it "should deliver mailings after period" do
      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.processed.count.should eq(0)

      Timecop.freeze @entity.created_at

      @mailing.conditions_met?(@entity).should be_truthy
      @mailing.processable?(@entity).should be_truthy
      @mailing.next_processing_time(@entity).should be <= @entity.created_at

      @mailing.logs(@entity).scheduled.count.should eq(1)
      schedule = @mailing.logs(@entity).scheduled.first

      @mailing.run

      schedule.reload
      schedule.status.should eq(:delivered)

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.processed.count.should eq(1)

      log = MailyHerald::Log.processed.first
      log.entity.should eq(@entity)
      log.entity_email.should eq(@entity.email)
      log.mailing.should eq(@mailing)

      @mailing.logs(@entity).processed.last.should eq(log)
      @mailing.last_processing_time(@entity).to_i.should eq(@entity.created_at.to_i)

      @mailing.logs(@entity).scheduled.count.should eq(1)

      @mailing.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.processed.count.should eq(1)

      Timecop.freeze @entity.created_at + @mailing.period + @mailing.period/3

      @mailing.logs(@entity).scheduled.count.should eq(1)

      @mailing.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.processed.count.should eq(2)

      Timecop.freeze @entity.created_at + @mailing.period + @mailing.period/2

      @mailing.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.processed.count.should eq(2)
    end

    it "should calculate valid next delivery date" do
      period = @mailing.period

      @mailing.last_processing_time(@entity).should be_nil
      @mailing.start_processing_time(@entity).should be_a(Time)
      @mailing.start_processing_time(@entity).should eq(@entity.created_at)
      @mailing.next_processing_time(@entity).to_i.should eq(@entity.created_at.to_i)
    end

    it "should handle processing with start date evaluated to the past date" do
      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.processed.count.should eq(0)

      @mailing.next_processing_time(@entity).to_i.should eq(@entity.created_at.to_i)
      start_at = @entity.created_at + 1.year

      Timecop.freeze start_at

      @mailing.conditions_met?(@entity).should be_truthy
      @mailing.processable?(@entity).should be_truthy

      @mailing.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.processed.count.should eq(1)
      @mailing.last_processing_time(@entity).to_i.should eq(start_at.to_i)

      Timecop.freeze start_at +1
      @mailing.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(1)

      @mailing.next_processing_time(@entity).to_i.should eq((start_at + @mailing.period).to_i)
      Timecop.freeze start_at + @mailing.period

      @mailing.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(2)
    end
  end

  pending "Error handling" do
    before do
      @old_start_at = @mailing.start_at
      @mailing.update_attribute(:start_at, "")
    end

    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
    end

    it "should handle start_at parsing errors or nil start time" do
      @mailing.last_processing_time(@entity).should be_nil
      @mailing.next_processing_time(@entity).should be_nil

      Timecop.freeze @entity.created_at
      @mailing.run

      @mailing.last_processing_time(@entity).should be_nil
      @mailing.next_processing_time(@entity).should be_nil
    end

    after do
      @mailing.update_attribute(:start_at, @old_start_at)
    end
  end

  describe "Without subscription" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    after(:each) do
      @mailing.update_attribute(:override_subscription, false)
    end

    it "should not deliver" do
      MailyHerald::Subscription.count.should eq(0)
      MailyHerald::Log.count.should eq(0)

      Timecop.freeze @entity.created_at

      @mailing.run

      MailyHerald::Subscription.count.should eq(0)
      MailyHerald::Log.count.should eq(0)
    end

    it "should not deliver individual mailing" do
      MailyHerald::Subscription.count.should eq(0)
      MailyHerald::Log.count.should eq(0)

      Timecop.freeze @entity.created_at

      expect{ @mailing.deliver_to @entity }.to raise_error(NoMethodError)

      MailyHerald::Subscription.count.should eq(0)
      MailyHerald::Log.count.should eq(0)
    end

    it "should deliver with subscription override" do
      MailyHerald::Subscription.count.should eq(0)
      MailyHerald::Log.count.should eq(0)

      @mailing.update_attribute(:override_subscription, true)
      MailyHerald::Log.scheduled.count.should eq(1)

      Timecop.freeze @entity.created_at

      @mailing.run

      MailyHerald::Subscription.count.should eq(0)
      MailyHerald::Log.delivered.count.should eq(1)
    end
  end

  describe "Conditions" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
    end

    it "should check mailing conditions" do
      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(0)

      Timecop.freeze @entity.created_at

      @mailing.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(1)

      @entity.update_attribute(:weekly_notifications, false)
      @entity.save

      Timecop.freeze @entity.created_at + @mailing.period + @mailing.period/3

      @mailing.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(1)
      MailyHerald::Log.skipped.count.should eq(1)

      @entity.update_attribute(:weekly_notifications, true)

      Timecop.freeze @entity.created_at + @mailing.period*2 + @mailing.period/3

      @mailing.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(2)
    end
  end
end
