require 'spec_helper'

describe MailyHerald::PeriodicalMailing do
  before(:each) do
    @mailing = MailyHerald.periodical_mailing(:weekly_summary)
    expect(@mailing).to be_kind_of(MailyHerald::PeriodicalMailing)
    expect(@mailing).not_to be_a_new_record

    @list = @mailing.list
    expect(@mailing.start_at).to eq("user.created_at")
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
      expect(MailyHerald::Log.scheduled.for_mailing(@mailing).count).to eq(1)
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
      expect(MailyHerald::Log.scheduled.for_mailing(@mailing).count).to eq(1)
      schedule = MailyHerald::Log.scheduled.for_mailing(@mailing).first
      expect(schedule.processing_at.to_i).to eq(@entity.created_at.to_i)

      time = Time.now + 10.days
      @mailing.update_attribute(:start_at, time.to_s)

      schedule.reload
      expect(schedule.processing_at.to_i).to eq(time.to_i)
    end

    it "should be triggered by unsubscribe" do
      expect(MailyHerald::Log.scheduled.for_mailing(@mailing).count).to eq(1)
      schedule = MailyHerald::Log.scheduled.for_mailing(@mailing).first
      expect(schedule.processing_at.to_i).to eq(@entity.created_at.to_i)

      @list.unsubscribe! @entity

      expect(MailyHerald::Log.scheduled.for_mailing(@mailing).first).to be_nil
    end

    it "should be triggered by disabling mailing" do
      expect(MailyHerald::Log.scheduled.for_mailing(@mailing).count).to eq(1)
      schedule = MailyHerald::Log.scheduled.for_mailing(@mailing).first
      expect(schedule.processing_at.to_i).to eq(@entity.created_at.to_i)

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
      expect(@entity).to be_kind_of(User)
      expect(@mailing.start_processing_time(@entity)).to be_kind_of(Time)
      expect(@mailing.next_processing_time(@entity)).to be_kind_of(Time)
      expect(@mailing.next_processing_time(@entity).to_i).to eq(@entity.created_at.to_i)
    end

    it "should use absolute start date if possible" do
      expect(@entity).to be_kind_of(User)
      time = (@entity.created_at + rand(100).days + rand(24).hours + rand(60).minutes).round
      @mailing.update_attribute(:start_at, time.to_s)

      expect(@mailing.start_processing_time(@entity)).to be_a(Time)
      expect(@mailing.next_processing_time(@entity)).to be_kind_of(Time)
      expect(@mailing.next_processing_time(@entity)).to eq(time)
    end
  end

  describe "Periodical Delivery" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
    end

    it "should deliver mailings periodically" do
      expect(@mailing.period).to eq 7.days

      expect(@mailing.last_processing_time(@entity)).to be_nil
      expect(@mailing.next_processing_time(@entity).to_i).to eq((@entity.created_at).to_i)

      Timecop.freeze @entity.created_at
      ret = @mailing.run
      expect(ret).to be_a(Array)
      expect(ret.first).to be_kind_of(MailyHerald::Log)
      expect(ret.first.mail).to be_kind_of(Mail::Message)
      expect(ret.first).to be_delivered

      expect(@mailing.last_processing_time(@entity).to_i).to eq @entity.created_at.to_i
      expect(@mailing.next_processing_time(@entity).to_i).to eq((@entity.created_at + 7.days).to_i)
    end

    it "should deliver mailings after period" do
      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(0)

      Timecop.freeze @entity.created_at

      expect(@mailing.conditions_met?(@entity)).to be_truthy
      expect(@mailing.processable?(@entity)).to be_truthy
      expect(@mailing.next_processing_time(@entity)).to be <= @entity.created_at

      expect(@mailing.logs(@entity).scheduled.count).to eq(1)
      schedule = @mailing.logs(@entity).scheduled.first

      @mailing.run

      schedule.reload
      expect(schedule.status).to eq(:delivered)

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(1)

      log = MailyHerald::Log.processed.first
      expect(log.entity).to eq(@entity)
      expect(log.entity_email).to eq(@entity.email)
      expect(log.mailing).to eq(@mailing)

      expect(@mailing.logs(@entity).processed.last).to eq(log)
      expect(@mailing.last_processing_time(@entity).to_i).to eq(@entity.created_at.to_i)

      expect(@mailing.logs(@entity).scheduled.count).to eq(1)

      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(1)

      Timecop.freeze @entity.created_at + @mailing.period + @mailing.period/3

      expect(@mailing.logs(@entity).scheduled.count).to eq(1)

      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(2)

      Timecop.freeze @entity.created_at + @mailing.period + @mailing.period/2

      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(2)
    end

    it "should calculate valid next delivery date" do
      period = @mailing.period

      expect(@mailing.last_processing_time(@entity)).to be_nil
      expect(@mailing.start_processing_time(@entity)).to be_kind_of(Time)
      expect(@mailing.start_processing_time(@entity)).to eq(@entity.created_at)
      expect(@mailing.next_processing_time(@entity).to_i).to eq(@entity.created_at.to_i)
    end

    it "should handle processing with start date evaluated to the past date" do
      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(0)

      expect(@mailing.next_processing_time(@entity).to_i).to eq(@entity.created_at.to_i)
      start_at = @entity.created_at + 1.year

      Timecop.freeze start_at

      expect(@mailing.conditions_met?(@entity)).to be_truthy
      expect(@mailing.processable?(@entity)).to be_truthy

      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(1)
      expect(@mailing.last_processing_time(@entity).to_i).to eq(start_at.to_i)

      Timecop.freeze start_at +1
      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)

      expect(@mailing.next_processing_time(@entity).to_i).to eq((start_at + @mailing.period).to_i)
      Timecop.freeze start_at + @mailing.period

      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(2)
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
      expect(@mailing.last_processing_time(@entity)).to be_nil
      expect(@mailing.next_processing_time(@entity)).to be_nil

      Timecop.freeze @entity.created_at
      @mailing.run

      expect(@mailing.last_processing_time(@entity)).to be_nil
      expect(@mailing.next_processing_time(@entity)).to be_nil
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
      expect(MailyHerald::Subscription.count).to eq(0)
      expect(MailyHerald::Log.count).to eq(0)

      Timecop.freeze @entity.created_at

      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(0)
      expect(MailyHerald::Log.count).to eq(0)
    end

    it "should not deliver individual mailing" do
      expect(MailyHerald::Subscription.count).to eq(0)
      expect(MailyHerald::Log.count).to eq(0)

      Timecop.freeze @entity.created_at

      expect{ @mailing.deliver_to @entity }.to raise_error(NoMethodError)

      expect(MailyHerald::Subscription.count).to eq(0)
      expect(MailyHerald::Log.count).to eq(0)
    end

    it "should deliver with subscription override" do
      expect(MailyHerald::Subscription.count).to eq(0)
      expect(MailyHerald::Log.count).to eq(0)

      @mailing.update_attribute(:override_subscription, true)
      expect(MailyHerald::Log.scheduled.count).to eq(1)

      Timecop.freeze @entity.created_at

      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(0)
      expect(MailyHerald::Log.delivered.count).to eq(1)
    end
  end

  describe "Conditions" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
    end

    it "should check mailing conditions" do
      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(0)

      Timecop.freeze @entity.created_at

      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(@mailing.schedule_for(@entity)).not_to be_nil

      @entity.update_attribute(:weekly_notifications, false)
      @entity.save

      Timecop.freeze @entity.created_at + @mailing.period + @mailing.period/3

      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(MailyHerald::Log.skipped.count).to eq(1)
      expect(@mailing.schedule_for(@entity)).not_to be_nil

      @entity.update_attribute(:weekly_notifications, true)

      Timecop.freeze @entity.created_at + @mailing.period*2 + @mailing.period/3

      @mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(2)
    end
  end

  describe "general scheduling" do
    before(:each) do
      @entity = FactoryGirl.create :user

      @mailing = MailyHerald.periodical_mailing(:general_scheduling_mailing) do |mailing|
        mailing.enable
        mailing.list = :generic_list
        mailing.subject = "Test mailing"
        mailing.start_at = Time.now.to_s
        mailing.period = 1.day
        mailing.template = "User name: {{user.name}}."
      end

      expect(@mailing).to be_valid
      expect(@mailing).to be_persisted
      expect(@mailing).to be_enabled
    end

    after(:each) do
      @mailing.destroy
    end

    it "should detect individual/general scheduling properly" do
      expect(@mailing.individual_scheduling?).to be_falsy

      @mailing.start_at = "user.created_at"
      expect(@mailing.individual_scheduling?).to be_truthy
    end

    it "should create schedules for the next period" do
      schedule = @mailing.schedule_for(@entity)
      expect(schedule).to be_nil

      time = Time.now - 5.hours
      @mailing.start_at = time
      @mailing.save!

      @list.subscribe!(@entity)

      schedule = @mailing.schedule_for(@entity)
      expect(schedule.processing_at.to_i).not_to eq(time.to_i)
      expect(schedule.processing_at.to_i).to eq((time + @mailing.period).to_i)
    end

    it "should create schedules for the first period" do
      schedule = @mailing.schedule_for(@entity)
      expect(schedule).to be_nil

      time = Time.now + 5.hours
      @mailing.start_at = time
      @mailing.save!

      @list.subscribe!(@entity)

      schedule = @mailing.schedule_for(@entity)
      expect(schedule.processing_at.to_i).to eq(time.to_i)
      expect(schedule.processing_at.to_i).not_to eq((time + @mailing.period).to_i)
    end
  end
end
