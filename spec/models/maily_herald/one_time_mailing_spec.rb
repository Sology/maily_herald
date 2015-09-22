require 'spec_helper'

describe MailyHerald::OneTimeMailing do
  before(:each) do
    @entity = FactoryGirl.create :user

    @list = MailyHerald.list(:generic_list)
    expect(@list.context).to be_a(MailyHerald::Context)
  end

  after(:all) do
    Timecop.return
  end

  describe "with subscription" do
    before(:each) do
      @list.subscribe!(@entity)
    end

    describe "run all delivery" do
      before(:each) do
        @mailing = MailyHerald.one_time_mailing(:test_mailing)
        expect(@mailing).to be_kind_of(MailyHerald::OneTimeMailing)
        expect(@mailing).not_to be_a_new_record
        expect(@mailing).to be_valid
      end

      it "should be delivered only once per user" do
        subscription = @mailing.subscription_for(@entity)

        expect(@mailing.logs.scheduled.count).to eq(1)
        expect(@mailing.schedules.for_entity(@entity).count).to eq(1)

        ret = @mailing.run

        expect(@mailing.logs.processed.for_entity(@entity).count).to eq(1)
        expect(@mailing.schedules.for_entity(@entity).count).to eq(0)

        @mailing.set_schedules

        expect(@mailing.schedules.for_entity(@entity).count).to eq(0)

        ret = @mailing.run

        expect(@mailing.logs.processed.for_entity(@entity).count).to eq(1)
        expect(@mailing.schedules.for_entity(@entity).count).to eq(0)
      end

      it "should be delivered" do
        subscription = @mailing.subscription_for(@entity)

        expect(MailyHerald::Subscription.count).to eq(1)
        expect(MailyHerald::Log.delivered.count).to eq(0)
        expect(@mailing.logs.scheduled.count).to eq(1)

        expect(subscription).to be_kind_of(MailyHerald::Subscription)

        expect(@mailing.conditions_met?(@entity)).to be_truthy
        expect(@mailing.processable?(@entity)).to be_truthy
        expect(@mailing.mailer_name).to eq(:generic)

        ret = @mailing.run
        expect(ret).to be_kind_of(Array)
        expect(ret.first).to be_kind_of(MailyHerald::Log)
        expect(ret.first).to be_delivered
        expect(ret.first.mail).to be_kind_of(Mail::Message)

        expect(MailyHerald::Subscription.count).to eq(1)
        expect(MailyHerald::Log.delivered.count).to eq(1)

        log = MailyHerald::Log.delivered.first
        expect(log.entity).to eq(@entity)
        expect(log.mailing).to eq(@mailing)
        expect(log.entity_email).to eq(@entity.email)
      end

      it "should handle template errors" do
        MailyHerald::Log.delivered.count.should eq(0)

        @mailing = MailyHerald.dispatch(:mail_with_error)
        schedule = @mailing.schedule_for(@entity)
        expect(schedule).to be_a(MailyHerald::Log)
        expect(schedule.processing_at).to be <= Time.now

        @mailing.run

        schedule.reload
        expect(schedule).to be_error
      end
    end

    describe "single entity delivery" do
      it "should not be possible via Mailer" do
        expect(MailyHerald::Log.delivered.count).to eq(0)

        schedule = MailyHerald.dispatch(:one_time_mail).schedule_for(@entity)
        schedule.update_attribute(:processing_at, Time.now + 1.day)

        expect{ CustomOneTimeMailer.one_time_mail(@entity).deliver }.not_to change{ActionMailer::Base.deliveries.count}

        expect(MailyHerald::Log.delivered.count).to eq(0)
      end
    end

    describe "with entity outside the scope" do
      before(:each) do
        @mailing = MailyHerald.one_time_mailing(:test_mailing)
      end

      it "should not process mailings, postpone them and finally skip them" do
        expect(@list.context.scope).to include(@entity)
        expect(@mailing).to be_processable(@entity)
        expect(@mailing).to be_enabled

        @entity.update_attribute(:active, false)

        expect(@list.context.scope).not_to include(@entity)
        expect(@list).to be_subscribed(@entity)

        expect(@mailing).not_to be_processable(@entity)

        schedule = @mailing.schedule_for(@entity)
        processing_at = schedule.processing_at
        expect(schedule).not_to be_nil
        expect(schedule.processing_at).to be <= Time.now
        
        @mailing.run

        schedule.reload
        expect(schedule).to be_scheduled
        expect(schedule.processing_at.to_i).to eq((Time.now + 1.day).to_i)
        expect(schedule.data[:original_processing_at]).to eq(processing_at)
        expect(schedule.data[:delivery_attempts].length).to eq(1)

        Timecop.freeze schedule.processing_at + 1

        @mailing.run

        schedule.reload
        expect(schedule).to be_scheduled
        expect(schedule.data[:delivery_attempts].length).to eq(2)

        Timecop.freeze schedule.processing_at + 1

        @mailing.run

        schedule.reload
        expect(schedule).to be_scheduled
        expect(schedule.data[:delivery_attempts].length).to eq(3)

        Timecop.freeze schedule.processing_at + 1

        @mailing.run

        schedule.reload
        expect(schedule).to be_skipped
        expect(schedule.data[:delivery_attempts].length).to eq(3)
        expect(schedule.data[:skip_reason]).to eq(:not_in_scope)
      end
    end
  end

  describe "with subscription override" do
    before(:each) do
      @mailing = MailyHerald.one_time_mailing(:one_time_mail)
      @mailing.update_attribute(:override_subscription, true)
    end

    after(:each) do
      @mailing.update_attribute(:override_subscription, false)
    end

    it "should deliver single mail" do
      expect(MailyHerald::Log.delivered.count).to eq(0)
      expect(@mailing.processable?(@entity)).to be_truthy
      expect(@mailing.override_subscription?).to be_truthy
      expect(@mailing.enabled?).to be_truthy
      @mailing.run
      expect(MailyHerald::Log.delivered.count).to eq(1)
    end
  end

  describe "with block start_at" do
    before(:each) do
      @mailing = MailyHerald::OneTimeMailing.new
      @mailing.title = "Foobar"
      @mailing.subject = "Foo"
      @mailing.template = "Sample template"
      @mailing.list = @list
      @mailing.start_at = Proc.new{|user| user.created_at + 1.hour}
      @mailing.enable
      @mailing.save!
    end

    after(:each) do
      @mailing.destroy
    end

    it "should be delivered" do
      expect(@mailing.has_start_at_proc?).to be_truthy

      expect(@mailing.processed_logs(@entity).count).to eq(0)
      expect(@mailing.schedules.for_entity(@entity).count).to eq(0)

      @list.subscribe!(@entity)

      expect(@list.subscription_for(@entity)).to be_a(MailyHerald::Subscription)
      expect(@list.subscription_for(@entity)).to be_active
      expect(@list.subscribed?(@entity)).to be_truthy

      # automatic schedule updater should be triggered
      expect(@mailing.schedules.for_entity(@entity).count).to eq(1)
      expect(@mailing.schedules.for_entity(@entity).last.processing_at.to_i).to eq((@entity.created_at + 1.hour).to_i)

      # manually setting schedules should not change anything now
      @mailing.set_schedules

      expect(@mailing.schedules.for_entity(@entity).count).to eq(1)
      expect(@mailing.schedules.for_entity(@entity).last.processing_at.to_i).to eq((@entity.created_at + 1.hour).to_i)
    end
  end

  describe "with block conditions" do
    before(:each) do
      @mailing = MailyHerald::OneTimeMailing.new
      @mailing.title = "Foobar"
      @mailing.subject = "Foo"
      @mailing.template = "Sample template"
      @mailing.list = @list
      @mailing.start_at = "user.created_at"
      @mailing.conditions = Proc.new {|user| user.weekly_notifications}
      @mailing.enable
      @mailing.save!
    end

    after(:each) do
      @mailing.destroy
      @entity.reload
      @entity.update_attribute(:weekly_notifications, true)
    end

    it "should deliver when positive" do
      expect(@mailing.has_conditions_proc?).to be_truthy

      @list.subscribe!(@entity)
      @mailing.set_schedules

      expect(@mailing.schedules.for_entity(@entity).count).to eq(1)

      schedule = @mailing.schedules.for_entity(@entity).last

      expect(schedule.processing_at.to_i).to eq(@entity.created_at.to_i)
      expect(@entity.weekly_notifications).to be_truthy
      expect(@mailing.conditions_met?(@entity)).to be_truthy

      @mailing.run

      schedule.reload
      expect(schedule.status).to eq(:delivered)
    end

    it "should skip when negative" do
      expect(@mailing.has_conditions_proc?).to be_truthy

      @list.subscribe!(@entity)
      @mailing.set_schedules

      expect(@mailing.schedules.for_entity(@entity).count).to eq(1)

      schedule = @mailing.schedules.for_entity(@entity).last

      expect(schedule.processing_at.to_i).to eq(@entity.created_at.to_i)

      @entity.update_attribute(:weekly_notifications, false)

      expect(@entity.weekly_notifications).to be_falsey
      expect(@mailing.conditions_met?(@entity)).to be_falsey

      @mailing.run

      schedule.reload
      expect(schedule.status).to eq(:skipped)
    end
  end
end
