require 'spec_helper'

describe MailyHerald::Sequence do
  before(:each) do
    @sequence = MailyHerald.sequence(:newsletters)
    expect(@sequence).to be_a MailyHerald::Sequence
    expect(@sequence).not_to be_a_new_record
    expect(@sequence.start_at).to eq("user.created_at")
    expect(@sequence.mailings.length).to eq(3)

    @list = @sequence.list
    expect(@list.name).to eq "generic_list"
  end

  after(:all) do
    Timecop.return
  end

  describe "Subscriptions" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
    end

    it "should find or initialize sequence subscription" do
      subscription = @sequence.subscription_for @entity
      expect(subscription).to be_valid
      expect(subscription).not_to be_a_new_record
      expect(subscription).to be_kind_of(MailyHerald::Subscription)
      expect(subscription).to be_active
    end

    it "should find or initialize sequence subscription via mailing" do
      subscription = @sequence.mailings.first.subscription_for @entity
      expect(subscription).to be_valid
      expect(subscription).not_to be_a_new_record
      expect(subscription).to be_kind_of(MailyHerald::Subscription)
      expect(subscription).to eq(@sequence.subscription_for(@entity))
      expect(subscription).to be_active
    end
  end

  describe "Updating schedules" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
      @subscription = @list.subscription_for(@entity)
      @mailing = @sequence.next_mailing(@entity)
    end

    after(:each) do
      @mailing.enable!
    end

    it "should be triggered by disabling mailing" do
      schedule = @sequence.schedule_for(@entity)

      expect(schedule.processing_at.to_i).to eq((@entity.created_at + @mailing.absolute_delay).to_i)

      @mailing.update_attribute :absolute_delay, 2.hours

      schedule = @sequence.schedule_for(@entity)
      expect(schedule.processing_at.to_i).to eq((@entity.created_at + 2.hours).to_i)

      @mailing.disable!
      schedule.reload
      expect(schedule.mailing.id).not_to eq(@mailing.id)
      expect(schedule.mailing.id).to eq(@sequence.next_mailing(@entity).id)
    end
  end

  describe "Markup evaluation" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
      @orig_start_at = @sequence.start_at
    end

    after(:each) do
      @sequence.update_attribute(:start_at, @orig_start_at)
    end

    it "should parse start_var" do
      expect(@entity).to be_a(User)
      expect(@sequence.processed_logs(@entity)).to be_empty
      expect(@sequence.next_processing_time(@entity)).to be_kind_of(Time)
    end

    it "should use absolute start date if provided and greater than evaluated start date" do
      expect(@entity).to be_kind_of(User)
      time = (@entity.created_at + rand(100).days + rand(24).hours + rand(60).minutes).round
      @sequence.start_at = time.to_s
      expect(@sequence.has_start_at_proc?).to be_falsey
      expect(@sequence.start_at_changed?).to be_truthy
      @sequence.save!
      expect(Time.parse(@sequence.start_at).to_i).to eq(time.to_i)
      expect(@sequence.next_processing_time(@entity)).to be_kind_of(Time)
      expect(@sequence.next_processing_time(@entity)).to eq(time + @sequence.mailings.first.absolute_delay)

      @subscription = @sequence.subscription_for(@entity)
      expect(@subscription).to be_active
      expect(@sequence.processed_mailings(@entity)).to be_empty
    end
  end

  describe "Scheduled Processing" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @template_tmp = @sequence.mailings[1].template
      @list.subscribe! @entity
      @subscription = @list.subscription_for(@entity)
    end

    after(:each) do
      @sequence.mailings[1].enable!
      @sequence.mailings[1].update_attribute(:conditions, nil)
      @sequence.mailings[1].update_attribute(:template, @template_tmp)
    end

    it "should deliver mailings with delays" do
      expect(@sequence.mailings.length).to eq(3)
      #@sequence.start).to be_nil

      expect(@sequence.processed_mailings(@entity).length).to eq(0)
      expect(@sequence.pending_mailings(@entity).length).to eq(@sequence.mailings.length)
      expect(@sequence.next_mailing(@entity).absolute_delay).not_to eq(0)
      expect(@sequence.next_processing_time(@entity).round).to eq((@entity.created_at + @sequence.mailings.first.absolute_delay).round)
      expect(@subscription).not_to be_a_new_record
      expect(@subscription).to be_active
      #@subscription).to be_processable
      expect(@subscription).not_to be_a_new_record

      schedule = @sequence.schedule_for(@entity)
      expect(schedule).to be_a(MailyHerald::Log)
      expect(schedule.processing_at.round).to eq((@entity.created_at + @sequence.mailings.first.absolute_delay).round)

      Timecop.freeze @entity.created_at

      @sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(0)

      Timecop.freeze @entity.created_at + @sequence.mailings.first.absolute_delay

      @sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      schedule.reload
      expect(schedule.status).to eq(:delivered)
      expect(MailyHerald::Log.delivered.count).to eq(1)

      expect(@sequence.processed_mailings(@entity).length).to eq(1)
      expect(@sequence.pending_mailings(@entity).length).to eq(@sequence.mailings.length - 1)
      expect(@sequence.pending_mailings(@entity).first).to eq(@sequence.mailings[1])
      
      expect(@sequence.last_processed_mailing(@entity)).to eq @sequence.mailings.first
      log = @sequence.mailing_processing_log_for(@entity, @sequence.mailings.first)
      expect(log.processing_at.to_i).to eq (@entity.created_at + @sequence.mailings.first.absolute_delay).to_i

      Timecop.freeze @entity.created_at + (@sequence.mailings[0].absolute_delay + @sequence.mailings[1].absolute_delay)/2.0

      @sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)

      Timecop.freeze @entity.created_at + @sequence.mailings[1].absolute_delay

      @sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(2) 

      log = @sequence.mailing_processing_log_for(@entity, @sequence.mailings.first)
      expect(log).to be_kind_of(MailyHerald::Log)
      expect(log.entity).to eq(@entity)

      log = @sequence.mailing_processing_log_for(@entity, @sequence.mailings[1])
      expect(log).to be_kind_of(MailyHerald::Log)
      expect(log.entity).to eq(@entity)
      expect(log.entity_email).to eq(@entity.email)
    end

    it "should handle processing with start date evaluated to the past date" do
      expect(@sequence.mailings.length).to eq(3)
      #expect(@sequence.start).to be_nil

      start_at = @entity.created_at.round + 1.year

      expect(@sequence.processed_mailings(@entity).length).to eq(0)
      expect(@sequence.pending_mailings(@entity).length).to eq(@sequence.mailings.length)
      expect(@sequence.next_mailing(@entity).absolute_delay).not_to eq(0)
      expect(@sequence.next_processing_time(@entity).round).to eq((@entity.created_at + @sequence.mailings.first.absolute_delay).round)

      Timecop.freeze start_at

      @sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)

      Timecop.freeze start_at + 1

      @sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)

      expect(@sequence.next_processing_time(@entity).to_i).to eq((start_at - @sequence.mailings.first.absolute_delay + @sequence.pending_mailings(@entity).first.absolute_delay).to_i)
      Timecop.freeze start_at - @sequence.mailings.first.absolute_delay + @sequence.pending_mailings(@entity).first.absolute_delay

      @sequence.run

      expect(MailyHerald::Subscription.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(2)
    end

    it "should calculate delivery times relatively based on existing logs" do
      expect(@sequence.mailings.length).to eq(3)
      #expect(@sequence.start).to be_nil

      Timecop.freeze @entity.created_at + @sequence.mailings[0].absolute_delay

      @sequence.run

      expect(MailyHerald::Log.delivered.count).to eq(1)

      Timecop.freeze @entity.created_at + @sequence.mailings[2].absolute_delay

      @sequence.run
      @sequence.run

      expect(MailyHerald::Log.delivered.count).to eq(2)

      Timecop.freeze @entity.created_at + @sequence.mailings[2].absolute_delay + (@sequence.mailings[2].absolute_delay - @sequence.mailings[1].absolute_delay)

      @sequence.run

      expect(MailyHerald::Log.delivered.count).to eq(3)
    end

    it "should skip disabled mailings and go on with processing" do
      expect(@sequence.mailings.length).to eq(3)
      #expect(@sequence.start).to be_nil
      expect(@sequence).to be_enabled

      expect(@sequence.mailings[0]).to be_enabled
      expect(@sequence.mailings[1]).to be_enabled
      expect(@sequence.mailings[2]).to be_enabled

      @sequence.mailings[1].disable!
      expect(@sequence.mailings[1]).not_to be_enabled

      expect(@sequence.pending_mailings(@entity).first).to eq(@sequence.mailings.first)
      expect(@sequence.pending_mailings(@entity).first).to be_enabled

      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay

      @sequence.run

      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(@sequence.processed_mailings(@entity).length).to eq(1)

      expect(@sequence.pending_mailings(@entity)).not_to include(@sequence.mailings[1])
      expect(@sequence.next_mailing(@entity)).to eq(@sequence.mailings[2])

      Timecop.freeze @entity.created_at + @sequence.mailings[2].absolute_delay

      @sequence.run

      expect(MailyHerald::Log.delivered.count).to eq(2)
      expect(@sequence.pending_mailings(@entity)).to be_empty
    end

    it "should skip mailings with unmet conditions and create logs for them" do
      @sequence.mailings[1].update_attribute(:conditions, "false")

      expect(@sequence.pending_mailings(@entity).first).to eq(@sequence.mailings.first)
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      expect(MailyHerald::Log.processed.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(MailyHerald::Log.skipped.count).to eq(0)
      expect(MailyHerald::Log.error.count).to eq(0)

      expect(@sequence.pending_mailings(@entity).first).to eq(@sequence.mailings[1])
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      expect(MailyHerald::Log.processed.count).to eq(2)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(MailyHerald::Log.skipped.count).to eq(1)
      expect(MailyHerald::Log.error.count).to eq(0)

      expect(@sequence.pending_mailings(@entity).first).to eq(@sequence.mailings[2])
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      expect(MailyHerald::Log.processed.count).to eq(3)
      expect(MailyHerald::Log.delivered.count).to eq(2)
      expect(MailyHerald::Log.skipped.count).to eq(1)
      expect(MailyHerald::Log.error.count).to eq(0)
    end

    pending "should skip mailings with errors and create logs for them" do
      @sequence.mailings[1].update_attribute(:template, "foo {{error =! here bar")

      expect(@sequence.pending_mailings(@entity).first).to eq(@sequence.mailings.first)
      expect(@sequence.processable?(@entity)).to be_truthy
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      expect(MailyHerald::Log.processed.count).to eq(1)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(MailyHerald::Log.skipped.count).to eq(0)
      expect(MailyHerald::Log.error.count).to eq(0)

      expect(@sequence.pending_mailings(@entity).first).to eq(@sequence.mailings[1])
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      expect(MailyHerald::Log.processed.count).to eq(2)
      expect(MailyHerald::Log.delivered.count).to eq(1)
      expect(MailyHerald::Log.skipped.count).to eq(0)
      expect(MailyHerald::Log.error.count).to eq(1)

      expect(@sequence.pending_mailings(@entity).first).to eq(@sequence.mailings[2])
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      expect(MailyHerald::Log.processed.count).to eq(3)
      expect(MailyHerald::Log.delivered.count).to eq(2)
      expect(MailyHerald::Log.skipped.count).to eq(0)
      expect(MailyHerald::Log.error.count).to eq(1)
    end

  end

  pending "Error handling" do
    before(:each) do
      @old_start_at = @sequence.start_at
      @sequence.update_attribute(:start_at, "")
      @entity = FactoryGirl.create :user
      @list.subscribe! @entity
    end

    after(:each) do
      @sequence.update_attribute(:start_at, @old_start_at)
    end

    it "should handle start_var parsing errors or nil start time" do
      expect(@sequence.start_at).to eq("")
      @sequence = @sequence.subscription_for @entity
      expect(@sequence.last_processing_time(@entity)).to be_nil
      expect(@sequence.next_processing_time(@entity)).to be_nil

      Timecop.freeze @entity.created_at
      @sequence.run

      @sequence = @sequence.subscription_for @entity
      expect(@sequence.last_processing_time(@entity)).to be_nil
      expect(@sequence.next_processing_time(@entity)).to be_nil
    end

    pending "should allow to set start date via text field" do
      datetime = "2013-01-01 10:11"

      @sequence.start_at = datetime
      expect(@sequence).to be_valid
      expect(@sequence.start_at).to eq(datetime)

      @sequence.start_at = ""
      expect(@sequence).to be_valid
    end
  end

  #describe "Without autosubscribe" do
    #before(:each) do
      #@sequence.update_attribute(:autosubscribe, false)
      #expect(@sequence).to be_valid
      #expect(@sequence.save).to be_truthy
      #@entity = FactoryGirl.create :user
    #end

    #after(:each) do
      #@sequence.update_attribute(:autosubscribe, true)
    #end

    #it "should create inactive subscription" do
      #subscription = @sequence.subscription_for @entity

      #expect(MailyHerald::MailingSubscription.count).to eq(0)
      #expect(MailyHerald::SequenceSubscription.count).to eq(1)
      #expect(MailyHerald::Log.count).to eq(0)

      #Timecop.freeze @entity.created_at

      #@sequence.run

      #expect(MailyHerald::MailingSubscription.count).to eq(0)
      #expect(MailyHerald::SequenceSubscription.count).to eq(1)
      #expect(MailyHerald::Log.count).to eq(0)
    #end
  #end

  pending "Subscription override" do
    before(:each) do
      @entity = FactoryGirl.create :user
    end

    after(:each) do
      @sequence.update_attribute(:override_subscription, false)
    end

    it "should be able to override subscription" do
      subscription = @sequence.subscription_for @entity

      expect(subscription).to be_active

      next_processing = @sequence.next_processing_time(@entity)

      subscription.deactivate!
      expect(subscription).not_to be_active

      expect(@sequence.logs(@entity).count).to eq(0)
      expect(@sequence.last_processing_time(@entity)).to be_nil

      Timecop.freeze next_processing

      @sequence.run

      expect(@sequence.logs(@entity).count).to eq(0)
      expect(@sequence.last_processing_time(@entity)).to be_nil

      @sequence.update_attribute(:override_subscription, true)

      @sequence.run

      expect(@sequence.logs(@entity).count).to eq(1)
      expect(@sequence.last_processing_time(@entity).to_i).to eq(next_processing.to_i)
    end
  end

  pending "unprocessable mailings - postponing them"

end
