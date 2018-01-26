require 'rails_helper'

describe MailyHerald::OneTimeMailing do

  let!(:entity) { create :user }
  let!(:list) { MailyHerald.list :generic_list }

  after(:all) { Timecop.return }

  it { expect(list.context).to be_a(MailyHerald::Context) }

  describe "#set_schedule_for" do
    describe "should not create schedules when start_at is nil" do
      let!(:mailing) { create(:generic_one_time_mailing, id: 101, start_at: Proc.new{|entity, subscription| entity.created_at unless entity.name == "skipme"}) }
      let!(:entity) { create :user, name: "skipme" }

      subject { mailing.set_schedule_for(entity) }

      it { expect(subject).to be_nil }
    end
  end

  describe "#run" do
    let!(:mailing) { create :generic_one_time_mailing }
    let!(:other_entity) { create :user }

    subject { mailing.run }

    describe "missing schedules" do
      context "with no subscription" do
        it("should not create schedules and skip them") do
          expect(subject.length).to eq(0)
          expect(mailing.logs.delivered.length).to eq(0)
        end
      end

      context "with subscription" do
        before { list.subscribe!(entity) }
        before { list.subscribe!(other_entity) }
        before { mailing.logs.where(entity: entity).delete_all }
        before { expect(mailing.logs.length).to eq(1) }

        context "start_at non nil" do
          it("should create schedules and deliver them") do
            expect(subject.length).to eq(2)
            expect(mailing.logs.delivered.length).to eq(2)
          end
        end

        context "start_at nil" do
          let!(:mailing) { create(:generic_one_time_mailing, id: 101, start_at: Proc.new{|entity, subscription| entity.created_at unless entity.name == "skipme"}) }
          let!(:entity) { create :user, name: "skipme" }

          it("should not create schedules and skip them") do
            expect(subject.length).to eq(2)
            expect(subject.compact.length).to eq(1)
            expect(mailing.logs.delivered.length).to eq(1)
          end
        end
      end
    end
  end

  describe "#delivery_scope" do
    let!(:mailing) { create :generic_one_time_mailing }

    before { list.subscribe!(entity) }

    subject { mailing.delivery_scope }

    context "when no schedule" do
      before { mailing.logs.where(entity: entity).delete_all }

      it("should contain entity") { expect(subject).to include(entity) }
    end

    context "when schedule exists" do
      it("should contain entity") { expect(subject).to include(entity) }
    end

    context "when has already been scheduled and delivered" do
      before { mailing.logs.where(entity: entity).update_all(status: "delivered") }

      it("should not contain entity") { expect(subject).to be_empty }
    end
  end

  context "with subscription" do
    before { list.subscribe!(entity) }

    context "run all delivery" do
      let!(:mailing) { create :generic_one_time_mailing }

      it { expect(mailing).to be_kind_of(MailyHerald::OneTimeMailing) }
      it { expect(mailing).not_to be_a_new_record }
      it { expect(mailing).to be_valid }

      context "delivery" do
        let!(:subscription) { mailing.subscription_for(entity) }

        it { expect(MailyHerald::Subscription.count).to eq(1) }
        it { expect(MailyHerald::Log.delivered.count).to eq(0) }

        it { expect(subscription).to be_kind_of(MailyHerald::Subscription) }

        it { expect(mailing.logs.scheduled.count).to eq(1) }
        it { expect(mailing.conditions_met?(entity)).to be_truthy }
        it { expect(mailing.processable?(entity)).to be_truthy }
        it { expect(mailing.mailer_name).to eq(:generic) }
        it { expect(mailing.schedules.for_entity(entity).count).to eq(1) }

        context "run" do
          let(:ret) { mailing.run }

          it { expect(ret).to be_kind_of(Array) }
          it { expect(ret.first).to be_kind_of(MailyHerald::Log) }
          it { expect(ret.first).to be_delivered }
          it { expect(ret.first.mail).to be_kind_of(Mail::Message) }

          context "after run" do
            before { ret; mailing.set_schedules }

            it { expect(MailyHerald::Subscription.count).to eq(1) }
            it { expect(MailyHerald::Log.delivered.count).to eq(1) }

            it { expect(mailing.logs.processed.for_entity(entity).count).to eq(1) }
            it { expect(mailing.schedules.for_entity(entity).count).to eq(0) }

            it "log should have proper values" do
              log = MailyHerald::Log.delivered.first
              expect(log.entity).to eq(entity)
              expect(log.mailing).to eq(mailing)
              expect(log.entity_email).to eq(entity.email)
            end

            context "runnning again" do
              before { ret }

              it { expect(mailing.logs.processed.for_entity(entity).count).to eq(1) }
              it { expect(mailing.schedules.for_entity(entity).count).to eq(0) }
            end
          end
        end
      end

      context "template errors", raise_delivery_errors: false do
        let!(:mailing) { create :mail_with_error }
        let!(:schedule) { mailing.schedule_for(entity) }

        before do
          expect(MailyHerald::Log.delivered.count).to eq(0)
          expect(schedule).to be_a(MailyHerald::Log)
          expect(schedule.processing_at).to be <= Time.now
          mailing.run
          schedule.reload
        end

        it { expect(schedule).to be_error }
      end
    end

    context "single entity delivery" do
      let!(:mailing)  { create :custom_one_time_mailing }
      let!(:schedule) { mailing.schedule_for(entity) }
      let(:mailer)    { mailing.mailer }

      before { schedule.update_attribute(:processing_at, Time.now + 1.day) }

      it { expect(mailing.logs.delivered.count).to eq(0) }
      it { expect{ mailer.one_time_mail(entity).deliver }.not_to change{ActionMailer::Base.deliveries.count} }
    end

    pending "with entity outside the scope - this shouldn't happen now as we're iterating over the scope" do
      let!(:mailing) { create :generic_one_time_mailing }

      context "check setup - active" do
        it { expect(list.context.scope).to include(entity) }
        it { expect(mailing).to be_processable(entity) }
        it { expect(mailing).to be_enabled }
      end

      context "after setup - non active" do
        before { entity.update_attributes!(active: false) }

        it { expect(list.context.scope).not_to include(entity) }
        it { expect(list).to be_subscribed(entity) }
        it { expect(mailing).not_to be_processable(entity) }

        it "should not process mailings, postpone them and finally skip them" do
          schedule = mailing.schedule_for(entity)
          processing_at = schedule.processing_at
          expect(schedule).not_to be_nil
          expect(schedule.processing_at).to be <= Time.now
          
          mailing.run

          schedule.reload
          expect(schedule).to be_scheduled
          expect(schedule.processing_at.to_i).to eq((Time.now + 1.day).to_i)
          expect(schedule.data[:original_processing_at]).to eq(processing_at)
          expect(schedule.data[:delivery_attempts].length).to eq(1)

          Timecop.freeze schedule.processing_at + 1

          mailing.run

          schedule.reload
          expect(schedule).to be_scheduled
          expect(schedule.data[:delivery_attempts].length).to eq(2)

          Timecop.freeze schedule.processing_at + 1

          mailing.run

          schedule.reload
          expect(schedule).to be_scheduled
          expect(schedule.data[:delivery_attempts].length).to eq(3)

          Timecop.freeze schedule.processing_at + 1

          mailing.run

          schedule.reload
          expect(schedule).to be_skipped
          expect(schedule.data[:delivery_attempts].length).to eq(3)
          expect(schedule.data[:skip_reason]).to eq(:not_in_scope)
        end
      end
    end
  end

  context "with block start_at" do
    # FIXME: Set the id manually so it doesn't interfere with other mailings that may have the same id during tests but no 'start_at' proc.
    let!(:mailing) { create :custom_one_time_mailing, id: 99, start_at: Proc.new{|user| user.created_at + 1.hour} }

    it { expect(mailing.has_start_at_proc?).to be_truthy }
    it { expect(mailing.processed_logs(entity).count).to eq(0) }
    it { expect(mailing.schedules.for_entity(entity).count).to eq(0) }

    context "after subscribing" do
      before { list.subscribe!(entity) }

      it { expect(list.subscription_for(entity)).to be_a(MailyHerald::Subscription) }
      it { expect(list.subscription_for(entity)).to be_active }
      it { expect(list.subscribed?(entity)).to be_truthy }

      context "automatic schedule updater should be triggered" do
        it { expect(mailing.schedules.for_entity(entity).count).to eq(1) }
        it { expect(mailing.schedules.for_entity(entity).last.processing_at.to_i).to eq((entity.created_at + 1.hour).to_i) }
      end

      context "manually setting schedules should not change anything now" do
        before { mailing.set_schedules }

        it { expect(mailing.schedules.for_entity(entity).count).to eq(1) }
        it { expect(mailing.schedules.for_entity(entity).last.processing_at.to_i).to eq((entity.created_at + 1.hour).to_i) }
      end
    end
  end

  context "with block conditions" do
    # FIXME: Set the id manually so it doesn't interfere with other mailings that may have the same id during tests but no 'start_at' proc.
    let!(:mailing) { create :custom_one_time_mailing, id: 100, conditions: Proc.new {|user| user.weekly_notifications} }

    it { expect(mailing.has_conditions_proc?).to be_truthy }

    context "when positive" do
      let!(:entity) { create :user, weekly_notifications: true }
      let(:schedule) { mailing.schedules.for_entity(entity).last }

      before do
        list.subscribe! entity
        mailing.set_schedule_for entity
      end

      it { expect(mailing.schedules.for_entity(entity).count).to eq(1) }
      it { expect(schedule.processing_at.to_i).to eq(entity.created_at.to_i) }
      it { expect(entity.weekly_notifications).to be_truthy }
      it { expect(mailing.conditions_met?(entity)).to be_truthy }

      it "should be delivered" do
        schedule = mailing.schedules.for_entity(entity).last
        mailing.run
        schedule.reload
        expect(schedule.status).to eq(:delivered)
      end
    end

    context "when negative" do
      let!(:entity) { create :user, weekly_notifications: false }

      before do
        list.subscribe! entity
        mailing.set_schedules
      end

      it { expect(mailing.schedules.for_entity(entity).count).to eq(1) }
      it { expect(mailing.schedules.for_entity(entity).last.processing_at.to_i).to eq(entity.created_at.to_i) }
      it { expect(entity.weekly_notifications).to be_falsey }
      it { expect(mailing.conditions_met?(entity)).to be_falsey }

      it "should be skipped" do
        schedule = mailing.schedules.for_entity(entity).last
        mailing.run
        schedule.reload
        expect(schedule.status).to eq(:skipped)
      end
    end
  end

end
