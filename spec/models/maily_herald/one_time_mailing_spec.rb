require 'spec_helper'

describe MailyHerald::OneTimeMailing do
  before(:each) do
    @entity = FactoryGirl.create :user

    @list = MailyHerald.list(:generic_list)
    expect(@list.context).to be_a(MailyHerald::Context)
  end

  describe "with subscription" do
    before(:each) do
      @list.subscribe!(@entity)
    end

    describe "run all delivery" do
      before(:each) do
        @mailing = MailyHerald.one_time_mailing(:test_mailing)
        @mailing.should be_a MailyHerald::OneTimeMailing
        @mailing.should_not be_a_new_record
        @mailing.should be_valid
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

        subscription.should be_kind_of(MailyHerald::Subscription)

        @mailing.conditions_met?(@entity).should be_truthy
        @mailing.processable?(@entity).should be_truthy
        @mailing.mailer_name.should eq(:generic)

        ret = @mailing.run
        ret.should be_a(Array)
        ret.first.should be_a(MailyHerald::Log)
        ret.first.should be_delivered
        ret.first.mail.should be_a(Mail::Message)

        MailyHerald::Subscription.count.should eq(1)
        MailyHerald::Log.delivered.count.should eq(1)

        log = MailyHerald::Log.delivered.first
        log.entity.should eq(@entity)
        log.mailing.should eq(@mailing)
        log.entity_email.should eq(@entity.email)
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
        MailyHerald::Log.delivered.count.should eq(0)

        schedule = MailyHerald.dispatch(:one_time_mail).schedule_for(@entity)
        schedule.update_attribute(:processing_at, Time.now + 1.day)

        expect{ CustomOneTimeMailer.one_time_mail(@entity).deliver }.not_to change{ActionMailer::Base.deliveries.count}

        MailyHerald::Log.delivered.count.should eq(0)
      end
    end

    describe "with entity outside the scope" do
      before(:each) do
        @mailing = MailyHerald.one_time_mailing(:test_mailing)
      end

      it "should not process mailings" do
        expect(@list.context.scope).to include(@entity)
        expect(@mailing).to be_processable(@entity)
        expect(@mailing).to be_enabled

        @entity.update_attribute(:active, false)

        expect(@list.context.scope).not_to include(@entity)
        expect(@list).to be_subscribed(@entity)

        expect(@mailing).not_to be_processable(@entity)
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
      MailyHerald::Log.delivered.count.should eq(0)
      @mailing.processable?(@entity).should be_truthy
      @mailing.override_subscription?.should be_truthy
      @mailing.enabled?.should be_truthy
      @mailing.run
      MailyHerald::Log.delivered.count.should eq(1)
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

      @list.subscribe!(@entity)
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
    end

    it "should be delivered" do
      expect(@mailing.has_conditions_proc?).to be_truthy

      @list.subscribe!(@entity)
      @mailing.set_schedules

      expect(@mailing.schedules.for_entity(@entity).count).to eq(1)
      expect(@mailing.schedules.for_entity(@entity).last.processing_at.to_i).to eq(@entity.created_at.to_i)
      expect(@entity.weekly_notifications).to be_truthy
      expect(@mailing.conditions_met?(@entity)).to be_truthy
    end
  end
end
