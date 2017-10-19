require 'rails_helper'

describe MailyHerald::PeriodicalMailing do

  let!(:mailing) { create :weekly_summary }
  let!(:list) { mailing.list }

  after { Timecop.return }

  context "setup" do
    it { expect(mailing).to be_kind_of(MailyHerald::PeriodicalMailing) }
    it { expect(mailing).not_to be_a_new_record }
    it { expect(mailing.start_at).to eq("user.created_at") }
  end

  context "subscribing" do
    let!(:entity) { create :user }

    before { list.subscribe! entity }

    it { expect(MailyHerald::Log.scheduled.for_mailing(mailing).count).to eq(1) }
  end

  context "updating schedules" do
    let!(:entity) { create :user }
    let!(:start_at) { mailing.start_at }
    let(:schedule) { MailyHerald::Log.scheduled.for_mailing(mailing).first }

    before { list.subscribe! entity }

    after do
      mailing.update_attributes!(start_at: start_at)
      mailing.update_attributes!(state: "enabled")
    end

    it { expect(MailyHerald::Log.scheduled.for_mailing(mailing).count).to eq(1) }
    it { expect(schedule.processing_at.to_i).to eq(entity.created_at.to_i) }

    context "triggered by start_at change" do
      let(:time) { Time.now + 10.days }

      before { mailing.update_attributes!(start_at: time.to_s); schedule.reload }

      it { expect(schedule.processing_at.to_i).to eq(time.to_i) }
    end

    context "triggered by unsubscribing" do
      before { list.unsubscribe! entity }

      it { expect(MailyHerald::Log.scheduled.for_mailing(mailing).first).to be_nil }
    end

    context "triggered by disabling mailing" do
      before { mailing.disable! }

      it { expect(MailyHerald::Log.scheduled.for_mailing(mailing).first).to be_nil }

      it "should be scheduled after enabling mailing again" do
        mailing.enable!
        expect(MailyHerald::Log.scheduled.for_mailing(mailing).first).not_to be_nil
      end
    end
  end

  context "start time evaluation" do
    let!(:entity) { create :user }
    let!(:start_at) { mailing.start_at }

    before { list.subscribe! entity }
    after { mailing.update_attributes!(start_at: start_at) }

    context "parsing start_at" do
      it { expect(mailing.scheduler_for(entity).start_processing_time).to be_kind_of(Time) }
      it { expect(mailing.scheduler_for(entity).next_processing_time).to be_kind_of(Time) }
      it { expect(mailing.scheduler_for(entity).next_processing_time.to_i).to eq(entity.created_at.to_i) }
    end

    context "using absolute start date if possible" do
      let(:time) { (entity.created_at + rand(100).days + rand(24).hours + rand(60).minutes).round }

      before { mailing.update_attributes!(start_at: time.to_s) }

      it { expect(mailing.scheduler_for(entity).start_processing_time).to be_a(Time) }
      it { expect(mailing.scheduler_for(entity).next_processing_time).to be_kind_of(Time) }
      it { expect(mailing.scheduler_for(entity).next_processing_time).to eq(time) }
    end
  end

  context "periodical delivery" do
    let!(:entity) { create :user }

    before { list.subscribe! entity }

    it { expect(MailyHerald::Subscription.count).to eq(1) }
    it { expect(MailyHerald::Log.processed.count).to eq(0) }
    it { expect(mailing.period).to eq 7.days }
    it { expect(mailing.scheduler_for(entity).last_processing_time).to be_nil }
    it { expect(mailing.scheduler_for(entity).next_processing_time.to_i).to eq((entity.created_at).to_i) }

    it "should deliver mailings periodically" do
      Timecop.freeze entity.created_at
      ret = mailing.run
      expect(ret).to be_a(Array)
      expect(ret.first).to be_kind_of(MailyHerald::Log)
      expect(ret.first.mail).to be_kind_of(Mail::Message)
      expect(ret.first).to be_delivered

      expect(mailing.scheduler_for(entity).last_processing_time.to_i).to eq entity.created_at.to_i
      expect(mailing.scheduler_for(entity).next_processing_time.to_i).to eq((entity.created_at + 7.days).to_i)
    end

    it "should deliver mailings after period" do
      Timecop.freeze entity.created_at

      expect(mailing.conditions_met?(entity)).to be_truthy
      expect(mailing.processable?(entity)).to be_truthy
      expect(mailing.scheduler_for(entity).next_processing_time).to be <= entity.created_at

      expect(mailing.logs.scheduled.count).to eq(1)
      schedule = mailing.logs.scheduled.first

      mailing.run

      schedule.reload
      expect(schedule.status).to eq(:delivered)

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(1)

      log = MailyHerald::Log.processed.first
      expect(log.entity).to eq(entity)
      expect(log.entity_email).to eq(entity.email)
      expect(log.mailing).to eq(mailing)

      expect(mailing.logs.processed.last).to eq(log)
      expect(mailing.scheduler_for(entity).last_processing_time.to_i).to eq(entity.created_at.to_i)

      expect(mailing.logs.scheduled.count).to eq(1)

      mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(1)

      Timecop.freeze entity.created_at + mailing.period + mailing.period/3

      expect(mailing.logs.scheduled.count).to eq(1)

      mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(2)

      Timecop.freeze entity.created_at + mailing.period + mailing.period/2

      mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(2)
    end

    it "should calculate valid next delivery date" do
      period = mailing.period

      expect(mailing.scheduler_for(entity).last_processing_time).to be_nil
      expect(mailing.scheduler_for(entity).start_processing_time).to be_kind_of(Time)
      expect(mailing.scheduler_for(entity).start_processing_time).to eq(entity.created_at)
      expect(mailing.scheduler_for(entity).next_processing_time.to_i).to eq(entity.created_at.to_i)
    end

    it "should handle processing with start date evaluated to the past date" do
      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(0)

      expect(mailing.scheduler_for(entity).next_processing_time.to_i).to eq(entity.created_at.to_i)
      start_at = entity.created_at + 1.year

      Timecop.freeze start_at

      expect(mailing.conditions_met?(entity)).to be_truthy
      expect(mailing.processable?(entity)).to be_truthy

      mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.processed.count).to eq(1)
      expect(mailing.scheduler_for(entity).last_processing_time.to_i).to eq(start_at.to_i)

      Timecop.freeze start_at +1
      mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)

      expect(mailing.scheduler_for(entity).next_processing_time.to_i).to eq((start_at + mailing.period).to_i)
      Timecop.freeze start_at + mailing.period

      mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(2)
    end
  end

  context "without subscription" do
    let!(:entity) { create :user }

    it { expect(MailyHerald::Subscription.count).to eq(0) }
    it { expect(MailyHerald::Log.count).to eq(0) }

    context "not delivering" do
      before { Timecop.freeze entity.created_at }

      it "should not go through" do
        mailing.run
        expect(MailyHerald::Subscription.count).to eq(0)
        expect(MailyHerald::Log.count).to eq(0)
      end

      it "should not go through individual mailing" do
        expect{ mailing.deliver_to entity }.to raise_error(NoMethodError)
        expect(MailyHerald::Subscription.count).to eq(0)
        expect(MailyHerald::Log.count).to eq(0)
      end
    end
  end

  context "conditions" do
    let!(:entity) { create :user }

    before { list.subscribe! entity }

    it { expect(MailyHerald::Subscription.count).to eq(1) }
    it { expect(MailyHerald::Log.delivered.count).to eq(0) }

    it "should check mailing conditions" do
      Timecop.freeze entity.created_at

      mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(mailing.scheduler_for(entity).schedule).not_to be_nil

      entity.update_attribute(:weekly_notifications, false)
      entity.save

      Timecop.freeze entity.created_at + mailing.period + mailing.period/3

      mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(MailyHerald::Log.skipped.count).to eq(1)
      expect(mailing.scheduler_for(entity).schedule).not_to be_nil

      entity.update_attribute(:weekly_notifications, true)

      Timecop.freeze entity.created_at + mailing.period*2 + mailing.period/3

      mailing.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(2)
    end
  end

  context "general scheduling" do
    let!(:entity) { create :user }
    let!(:mailing) { create :weekly_summary, name: :general_scheduling_mailing, start_at: Time.now.to_s, period: 1.day }

    it { expect(mailing).to be_valid }
    it { expect(mailing).to be_persisted }
    it { expect(mailing).to be_enabled }

    it "should detect individual/general scheduling properly" do
      expect(mailing.individual_scheduling?).to be_falsy

      mailing.start_at = "user.created_at"
      expect(mailing.individual_scheduling?).to be_truthy
    end

    context "creating schedules" do
      before do
        expect(mailing.scheduler_for(entity).schedule).to be_nil
        mailing.start_at = time
        mailing.save!
      end

      context "for the next period" do
        let(:time) { Time.now - 5.hours }

        before { list.subscribe! entity }

        it { expect(mailing.scheduler_for(entity).schedule.processing_at.to_i).not_to eq(time.to_i) }
        it { expect(mailing.scheduler_for(entity).schedule.processing_at.to_i).to eq((time + mailing.period).to_i) }
      end

      context "for the first period" do
        let(:time) { Time.now + 5.hours }

        before { list.subscribe! entity }

        it { expect(mailing.scheduler_for(entity).schedule.processing_at.to_i).to eq(time.to_i) }
        it { expect(mailing.scheduler_for(entity).schedule.processing_at.to_i).not_to eq((time + mailing.period).to_i) }
      end
    end
  end

  context "error handling" do
    let!(:entity) { create :user }

    before do
      list.subscribe! entity
      mailing.update_attribute(:start_at, "wrong")
    end

    it { expect(mailing.scheduler_for(entity).last_processing_time).to be_nil }
    it { expect(mailing.scheduler_for(entity).next_processing_time).to be_nil }

    context "after running" do
      before do
        Timecop.freeze entity.created_at
        mailing.run
      end

      it { expect(mailing.scheduler_for(entity).last_processing_time).to be_nil }
      it { expect(mailing.scheduler_for(entity).next_processing_time).to be_nil }    
    end
  end

end
