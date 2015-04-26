require 'spec_helper'

describe MailyHerald::AdHocMailing do
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
        @mailing = MailyHerald.ad_hoc_mailing(:ad_hoc_mail)
        @mailing.should be_a MailyHerald::AdHocMailing
        @mailing.should_not be_a_new_record
      end

      it "should not be delivered without explicit scheduling" do
        expect(MailyHerald::Subscription.count).to eq(1)
        @mailing.conditions_met?(@entity).should be_truthy
        @mailing.processable?(@entity).should be_truthy

        expect(@mailing.logs.scheduled.count).to eq(0)
        expect(@mailing.logs.processed.count).to eq(0)

        @mailing.run

        expect(@mailing.logs.scheduled.count).to eq(0)
        expect(@mailing.logs.processed.count).to eq(0)
      end

      it "should be delivered" do
        subscription = @mailing.subscription_for(@entity)

        expect(MailyHerald::Subscription.count).to eq(1)
        expect(MailyHerald::Log.delivered.count).to eq(0)

        subscription.should be_kind_of(MailyHerald::Subscription)

        @mailing.conditions_met?(@entity).should be_truthy
        @mailing.processable?(@entity).should be_truthy

        @mailing.schedule_delivery_to_all Time.now - 5

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
    end

    describe "single entity delivery" do
      before(:each) do
        @mailing = MailyHerald.ad_hoc_mailing(:ad_hoc_mail)
        @mailing.should be_a MailyHerald::AdHocMailing
        @mailing.should_not be_a_new_record
      end

      it "should not be delivered without explicit scheduling" do
        MailyHerald::Log.delivered.count.should eq(0)
        msg = AdHocMailer.ad_hoc_mail(@entity).deliver
        msg.should be_a(Mail::Message)
        MailyHerald::Log.delivered.count.should eq(0)
      end

      it "should be delivered" do
        MailyHerald::Log.delivered.count.should eq(0)

        @mailing.schedule_delivery_to @entity, Time.now - 5

        msg = AdHocMailer.ad_hoc_mail(@entity).deliver

        msg.should be_a(Mail::Message)
        MailyHerald::Log.delivered.count.should eq(1)
      end

      it "should not be delivered if subscription inactive" do
        @mailing.schedule_delivery_to @entity, Time.now - 5

        @list.unsubscribe!(@entity)

        MailyHerald::Log.delivered.count.should eq(0)

        AdHocMailer.ad_hoc_mail(@entity).deliver

        MailyHerald::Log.delivered.count.should eq(0)
      end
    end

    describe "with entity outside the scope" do
      before(:each) do
        @mailing = MailyHerald.ad_hoc_mailing(:ad_hoc_mail)
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
      @mailing = MailyHerald.ad_hoc_mailing(:ad_hoc_mail)
      @mailing.update_attribute(:override_subscription, true)
    end

    after(:each) do
      @mailing.update_attribute(:override_subscription, false)
    end

    it "single mail should be delivered" do
      MailyHerald::Log.delivered.count.should eq(0)
      @mailing.processable?(@entity).should be_truthy
      @mailing.override_subscription?.should be_truthy
      @mailing.enabled?.should be_truthy

      @mailing.schedule_delivery_to @entity, Time.now - 5

      msg = AdHocMailer.ad_hoc_mail(@entity).deliver
      msg.should be_a(Mail::Message)

      MailyHerald::Log.delivered.count.should eq(1)
    end
  end

end
