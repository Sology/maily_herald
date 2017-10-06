require 'rails_helper'

describe MailyHerald::Sequence do

  let!(:sequence) { create :newsletters }
  let!(:list) { sequence.list }

  after(:all) { Timecop.return }

  context "initial" do
    it { expect(sequence).to be_a MailyHerald::Sequence }
    it { expect(sequence).not_to be_a_new_record }
    it { expect(sequence.start_at).to eq("user.created_at") }
    it { expect(sequence.mailings.length).to eq(3) }
    it { expect(list).to be_a MailyHerald::List }
    it { expect(list.name).to eq "generic_list" }
  end

  context "subscriptions" do
    let!(:entity) { create :user }

    before { list.subscribe! entity }

    context "find or initialize sequence subscription via sequence" do
      let(:subscription) { sequence.subscription_for entity }

      it { expect(subscription).to be_valid }
      it { expect(subscription).not_to be_a_new_record }
      it { expect(subscription).to be_kind_of(MailyHerald::Subscription) }
      it { expect(subscription).to be_active }
    end

    context "find or initialize sequence subscription via mailing" do
      let(:subscription) { sequence.mailings.first.subscription_for entity }

      it { expect(subscription).to be_valid }
      it { expect(subscription).not_to be_a_new_record }
      it { expect(subscription).to be_kind_of(MailyHerald::Subscription) }
      it { expect(subscription).to eq(sequence.subscription_for(entity)) }
      it { expect(subscription).to be_active }
    end
  end

  context "updating schedules" do
    let!(:entity) { create :user }
    let!(:mailing) { sequence.next_mailing(entity) }
    let(:schedule) { sequence.schedule_for(entity) }

    before { list.subscribe! entity }

    it { expect(schedule.processing_at.to_i).to eq((entity.created_at + mailing.absolute_delay).to_i) }

    it "should be triggered by disabling mailing" do
      mailing.update_attribute :absolute_delay, 2.hours

      schedule = sequence.schedule_for(entity)
      expect(schedule.processing_at.to_i).to eq((entity.created_at + 2.hours).to_i)

      mailing.disable!
      schedule.reload
      expect(schedule.mailing.id).not_to eq(mailing.id)
      expect(schedule.mailing.id).to eq(sequence.next_mailing(entity).id)
    end
  end

  context "markup evaluation" do
    let!(:entity) { create :user }

    before { list.subscribe! entity }

    it { expect(sequence.processed_logs(entity)).to be_empty }
    it { expect(sequence.next_processing_time(entity)).to be_kind_of(Time) }

    context "provided and greater than evaluated start date" do
      let(:time) { (entity.created_at + rand(100).days + rand(24).hours + rand(60).minutes).round }

      before do
        sequence.start_at = time.to_s
        expect(sequence.has_start_at_proc?).to be_falsey
        expect(sequence.start_at_changed?).to be_truthy
        sequence.save!
      end

      it { expect(Time.parse(sequence.start_at).to_i).to eq(time.to_i) }
      it { expect(sequence.next_processing_time(entity)).to be_kind_of(Time) }
      it { expect(sequence.next_processing_time(entity)).to eq(time + sequence.mailings.first.absolute_delay) }

      it "subscription should be active and processed mailings for entity should be empty" do
        subscription = sequence.subscription_for(entity)
        expect(subscription).to be_active
        expect(sequence.processed_mailings(entity)).to be_empty
      end
    end
  end

  context "scheduled processing" do
    let!(:entity) { create :user }
    let!(:template_tmp) { sequence.mailings[1].template }
    let(:subscription) { list.subscription_for(entity) }

    before { list.subscribe! entity }

    it { expect(subscription).not_to be_a_new_record }
    it { expect(subscription).to be_active }

    it { expect(sequence.processed_mailings(entity).length).to eq(0) }
    it { expect(sequence.pending_mailings(entity).length).to eq(sequence.mailings.length) }
    it { expect(sequence.next_mailing(entity).absolute_delay).not_to eq(0) }
    it { expect(sequence.next_processing_time(entity).round).to eq((entity.created_at + sequence.mailings.first.absolute_delay).round) }

    it { expect(sequence).to be_enabled }
    it { expect(sequence.mailings[0]).to be_enabled }
    it { expect(sequence.mailings[1]).to be_enabled }
    it { expect(sequence.mailings[2]).to be_enabled }

    pending "should deliver mailings with delays" do
      schedule = sequence.schedule_for(entity)
      expect(schedule).to be_a(MailyHerald::Log)
      expect(schedule.processing_at.round).to eq((entity.created_at + sequence.mailings.first.absolute_delay).round)

      Timecop.freeze entity.created_at

      sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(0)

      Timecop.freeze entity.created_at + sequence.mailings.first.absolute_delay

      sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      schedule.reload
      expect(schedule.status).to eq(:delivered)
      expect(MailyHerald::Log.delivered.count).to eq(1)

      expect(sequence.processed_mailings(entity).length).to eq(1)
      expect(sequence.pending_mailings(entity).length).to eq(sequence.mailings.length - 1)
      expect(sequence.pending_mailings(entity).first).to eq(sequence.mailings[1])
      
      expect(sequence.last_processed_mailing(entity)).to eq sequence.mailings.first
      log = sequence.mailing_processing_log_for(entity, sequence.mailings.first)
      expect(log.processing_at.to_i).to eq (entity.created_at + sequence.mailings.first.absolute_delay).to_i

      Timecop.freeze entity.created_at + (sequence.mailings[0].absolute_delay + sequence.mailings[1].absolute_delay)/2.0

      sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)

      Timecop.freeze entity.created_at + sequence.mailings[1].absolute_delay

      sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(2) 

      log = sequence.mailing_processing_log_for(entity, sequence.mailings.first)
      expect(log).to be_kind_of(MailyHerald::Log)
      expect(log.entity).to eq(entity)

      log = sequence.mailing_processing_log_for(entity, sequence.mailings[1])
      expect(log).to be_kind_of(MailyHerald::Log)
      expect(log.entity).to eq(entity)
      expect(log.entity_email).to eq(entity.email)
    end

    pending "should handle processing with start date evaluated to the past date" do
      start_at = entity.created_at.round + 1.year

      expect(sequence.processed_mailings(entity).length).to eq(0)
      expect(sequence.pending_mailings(entity).length).to eq(sequence.mailings.length)
      expect(sequence.next_mailing(entity).absolute_delay).not_to eq(0)
      expect(sequence.next_processing_time(entity).round).to eq((entity.created_at + sequence.mailings.first.absolute_delay).round)

      Timecop.freeze start_at

      sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)

      Timecop.freeze start_at + 1

      sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)

      expect(sequence.next_processing_time(entity).to_i).to eq((start_at - sequence.mailings.first.absolute_delay + sequence.pending_mailings(entity).first.absolute_delay).to_i)
      Timecop.freeze start_at - sequence.mailings.first.absolute_delay + sequence.pending_mailings(entity).first.absolute_delay

      sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(2)
    end

    pending "should calculate delivery times relatively based on existing logs" do
      Timecop.freeze entity.created_at + sequence.mailings[0].absolute_delay

      sequence.run

      expect(MailyHerald::Log.delivered.count).to eq(1)

      Timecop.freeze entity.created_at + sequence.mailings[2].absolute_delay

      sequence.run
      sequence.run

      expect(MailyHerald::Log.delivered.count).to eq(2)

      Timecop.freeze entity.created_at + sequence.mailings[2].absolute_delay + (sequence.mailings[2].absolute_delay - sequence.mailings[1].absolute_delay)

      sequence.run

      expect(MailyHerald::Log.delivered.count).to eq(3)
    end

    pending "should skip disabled mailings and go on with processing" do
      sequence.mailings[1].disable!
      expect(sequence.mailings[1]).not_to be_enabled

      expect(sequence.pending_mailings(entity).first).to eq(sequence.mailings.first)
      expect(sequence.pending_mailings(entity).first).to be_enabled

      Timecop.freeze entity.created_at + sequence.pending_mailings(entity).first.absolute_delay

      sequence.run

      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(sequence.processed_mailings(entity).length).to eq(1)

      expect(sequence.pending_mailings(entity)).not_to include(sequence.mailings[1])
      expect(sequence.next_mailing(entity)).to eq(sequence.mailings[2])

      Timecop.freeze entity.created_at + sequence.mailings[2].absolute_delay

      sequence.run

      expect(MailyHerald::Log.delivered.count).to eq(2)
      expect(sequence.pending_mailings(entity)).to be_empty
    end

    pending "should skip mailings with unmet conditions and create logs for them" do
      sequence.mailings[1].update_attributes!(conditions: "false")

      expect(sequence.pending_mailings(entity).first).to eq(sequence.mailings.first)
      Timecop.freeze entity.created_at + sequence.pending_mailings(entity).first.absolute_delay

      sequence.run
      expect(MailyHerald::Log.processed.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(MailyHerald::Log.skipped.count).to eq(0)
      expect(MailyHerald::Log.error.count).to eq(0)

      expect(sequence.pending_mailings(entity).first).to eq(sequence.mailings[1])
      Timecop.freeze entity.created_at + sequence.pending_mailings(entity).first.absolute_delay

      sequence.run
      expect(MailyHerald::Log.processed.count).to eq(2)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(MailyHerald::Log.skipped.count).to eq(1)
      expect(MailyHerald::Log.error.count).to eq(0)

      expect(sequence.pending_mailings(entity).first).to eq(sequence.mailings[2])
      Timecop.freeze entity.created_at + sequence.pending_mailings(entity).first.absolute_delay

      sequence.run
      expect(MailyHerald::Log.processed.count).to eq(3)
      expect(MailyHerald::Log.delivered.count).to eq(2)
      expect(MailyHerald::Log.skipped.count).to eq(1)
      expect(MailyHerald::Log.error.count).to eq(0)
    end

    pending "should skip mailings with errors and create logs for them" do
      sequence.mailings[1].update_attributes(template: "foo {{error =! here bar")

      expect(sequence.pending_mailings(entity).first).to eq(sequence.mailings.first)
      expect(sequence.processable?(entity)).to be_truthy
      Timecop.freeze entity.created_at + sequence.pending_mailings(entity).first.absolute_delay

      sequence.run
      expect(MailyHerald::Log.processed.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(MailyHerald::Log.skipped.count).to eq(0)
      expect(MailyHerald::Log.error.count).to eq(0)

      expect(sequence.pending_mailings(entity).first).to eq(sequence.mailings[1])
      Timecop.freeze entity.created_at + sequence.pending_mailings(entity).first.absolute_delay

      sequence.run
      expect(MailyHerald::Log.processed.count).to eq(2)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(MailyHerald::Log.skipped.count).to eq(0)
      expect(MailyHerald::Log.error.count).to eq(1)

      expect(sequence.pending_mailings(entity).first).to eq(sequence.mailings[2])
      Timecop.freeze entity.created_at + sequence.pending_mailings(entity).first.absolute_delay

      sequence.run
      expect(MailyHerald::Log.processed.count).to eq(3)
      expect(MailyHerald::Log.delivered.count).to eq(2)
      expect(MailyHerald::Log.skipped.count).to eq(0)
      expect(MailyHerald::Log.error.count).to eq(1)
    end
  end

  context "subscription override" do
    let!(:entity) { create :user }
    let(:subscription) { sequence.subscription_for entity }
    let(:next_processing) { sequence.next_processing_time entity }

    before { list.subscribe! entity }

    it { expect(subscription).to be_active }

    context "deactivate!" do
      before { subscription.deactivate! }

      it { expect(subscription).not_to be_active }
      it { expect(sequence.logs.count).to eq(0) }
      it { expect(sequence.last_processing_time(entity)).to be_nil }

      pending "should be able to override subscription" do
        Timecop.freeze next_processing

        sequence.run

        expect(sequence.logs.count).to eq(0)
        expect(sequence.last_processing_time(entity)).to be_nil

        sequence.update_attributes!(override_subscription: true)
        sequence.run

        expect(sequence.logs.count).to eq(1)
        expect(sequence.last_processing_time(entity).to_i).to eq(next_processing.to_i)
      end
    end
  end

  context "error handling" do
    let!(:entity) { create :user }

    before do
      sequence.update_attributes!(start_at: "wrong")
      list.subscribe! entity
    end

    it { expect(sequence.start_at).to eq("wrong") }

    it "should handle start_var parsing errors or nil start time" do
      expect(sequence.last_processing_time(entity)).to be_nil
      expect(sequence.next_processing_time(entity)).to be_nil

      Timecop.freeze entity.created_at
      sequence.run

      expect(sequence.last_processing_time(entity)).to be_nil
      expect(sequence.next_processing_time(entity)).to be_nil
    end

    it "should allow to set start date via text field" do
      datetime = "2013-01-01 10:11"

      sequence.start_at = datetime
      expect(sequence).to be_valid
      expect(sequence.start_at).to eq(datetime)

      sequence.start_at = "wrong"
      expect(sequence).to be_valid
    end
  end
end
