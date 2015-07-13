require 'spec_helper'

describe MailyHerald::Sequence do
  before(:each) do
    @sequence = MailyHerald.sequence(:newsletters)
    @sequence.should be_a MailyHerald::Sequence
    @sequence.should_not be_a_new_record
    @sequence.start_at.should eq("user.created_at")
    @sequence.mailings.length.should eq(3)

    @list = @sequence.list
    @list.name.should eq "generic_list"
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
      subscription.should be_valid
      subscription.should_not be_a_new_record
      subscription.should be_a(MailyHerald::Subscription)
      subscription.should be_active
    end

    it "should find or initialize sequence subscription via mailing" do
      subscription = @sequence.mailings.first.subscription_for @entity
      subscription.should be_valid
      subscription.should_not be_a_new_record
      subscription.should be_a(MailyHerald::Subscription)
      subscription.should eq(@sequence.subscription_for(@entity))
      subscription.should be_active
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
      @entity.should be_a(User)
      @sequence.processed_logs(@entity).should be_empty
      @sequence.next_processing_time(@entity).should be_a(Time)
    end

    it "should use absolute start date if provided and greater that evaluated start date" do
      @entity.should be_a(User)
      time = (@entity.created_at + rand(100).days + rand(24).hours + rand(60).minutes).round
      @sequence.start_at = time.to_s
      @sequence.save
      @sequence.next_processing_time(@entity).should be_a(Time)
      @sequence.next_processing_time(@entity).should eq(time + @sequence.mailings.first.absolute_delay)

      @subscription = @sequence.subscription_for(@entity)
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
      @sequence.mailings.length.should eq(3)
      #@sequence.start.should be_nil

      @sequence.processed_mailings(@entity).length.should eq(0)
      @sequence.pending_mailings(@entity).length.should eq(@sequence.mailings.length)
      @sequence.next_mailing(@entity).absolute_delay.should_not eq(0)
      @sequence.next_processing_time(@entity).round.should eq((@entity.created_at + @sequence.mailings.first.absolute_delay).round)
      @subscription.should_not be_a_new_record
      @subscription.should be_active
      #@subscription.should be_processable
      @subscription.should_not be_a_new_record

      schedule = @sequence.schedule_for(@entity)
      expect(schedule).to be_a(MailyHerald::Log)
      expect(schedule.processing_at.round).to eq((@entity.created_at + @sequence.mailings.first.absolute_delay).round)

      Timecop.freeze @entity.created_at

      @sequence.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(0)

      Timecop.freeze @entity.created_at + @sequence.mailings.first.absolute_delay

      @sequence.run

      MailyHerald::Subscription.count.should eq(1)
      schedule.reload
      expect(schedule.status).to eq(:delivered)
      MailyHerald::Log.delivered.count.should eq(1)

      @sequence.processed_mailings(@entity).length.should eq(1)
      @sequence.pending_mailings(@entity).length.should eq(@sequence.mailings.length - 1)
      @sequence.pending_mailings(@entity).first.should eq(@sequence.mailings[1])
      
      @sequence.last_processed_mailing(@entity).should eq @sequence.mailings.first
      log = @sequence.mailing_processing_log_for(@entity, @sequence.mailings.first)
      log.processing_at.to_i.should eq (@entity.created_at + @sequence.mailings.first.absolute_delay).to_i

      Timecop.freeze @entity.created_at + (@sequence.mailings[0].absolute_delay + @sequence.mailings[1].absolute_delay)/2.0

      @sequence.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(1)

      Timecop.freeze @entity.created_at + @sequence.mailings[1].absolute_delay

      @sequence.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(2) 

      log = @sequence.mailing_processing_log_for(@entity, @sequence.mailings.first)
      log.should be_a(MailyHerald::Log)
      log.entity.should eq(@entity)

      log = @sequence.mailing_processing_log_for(@entity, @sequence.mailings[1])
      log.should be_a(MailyHerald::Log)
      log.entity.should eq(@entity)
      log.entity_email.should eq(@entity.email)
    end

    it "should handle processing with start date evaluated to the past date" do
      @sequence.mailings.length.should eq(3)
      #@sequence.start.should be_nil

      start_at = @entity.created_at.round + 1.year

      @sequence.processed_mailings(@entity).length.should eq(0)
      @sequence.pending_mailings(@entity).length.should eq(@sequence.mailings.length)
      @sequence.next_mailing(@entity).absolute_delay.should_not eq(0)
      @sequence.next_processing_time(@entity).round.should eq((@entity.created_at + @sequence.mailings.first.absolute_delay).round)

      Timecop.freeze start_at

      @sequence.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(1)

      Timecop.freeze start_at + 1

      @sequence.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(1)

      @sequence.next_processing_time(@entity).to_i.should eq((start_at - @sequence.mailings.first.absolute_delay + @sequence.pending_mailings(@entity).first.absolute_delay).to_i)
      Timecop.freeze start_at - @sequence.mailings.first.absolute_delay + @sequence.pending_mailings(@entity).first.absolute_delay

      @sequence.run

      MailyHerald::Subscription.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(2)
    end

    it "should calculate delivery times relatively based on existing logs" do
      @sequence.mailings.length.should eq(3)
      #@sequence.start.should be_nil

      Timecop.freeze @entity.created_at + @sequence.mailings[0].absolute_delay

      @sequence.run

      MailyHerald::Log.delivered.count.should eq(1)

      Timecop.freeze @entity.created_at + @sequence.mailings[2].absolute_delay

      @sequence.run
      @sequence.run

      MailyHerald::Log.delivered.count.should eq(2)

      Timecop.freeze @entity.created_at + @sequence.mailings[2].absolute_delay + (@sequence.mailings[2].absolute_delay - @sequence.mailings[1].absolute_delay)

      @sequence.run

      MailyHerald::Log.delivered.count.should eq(3)
    end

    it "should skip disabled mailings and go on with processing" do
      @sequence.mailings.length.should eq(3)
      #@sequence.start.should be_nil
      @sequence.should be_enabled

      @sequence.mailings[0].should be_enabled
      @sequence.mailings[1].should be_enabled
      @sequence.mailings[2].should be_enabled

      @sequence.mailings[1].disable!
      @sequence.mailings[1].should_not be_enabled

      @sequence.pending_mailings(@entity).first.should eq(@sequence.mailings.first)
      @sequence.pending_mailings(@entity).first.should be_enabled

      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay

      @sequence.run

      MailyHerald::Log.delivered.count.should eq(1)
      @sequence.processed_mailings(@entity).length.should eq(1)

      @sequence.pending_mailings(@entity).should_not include(@sequence.mailings[1])
      @sequence.next_mailing(@entity).should eq(@sequence.mailings[2])

      Timecop.freeze @entity.created_at + @sequence.mailings[2].absolute_delay

      @sequence.run

      MailyHerald::Log.delivered.count.should eq(2)
      @sequence.pending_mailings(@entity).should be_empty
    end

    it "should skip mailings with unmet conditions and create logs for them" do
      @sequence.mailings[1].update_attribute(:conditions, "false")

      @sequence.pending_mailings(@entity).first.should eq(@sequence.mailings.first)
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      MailyHerald::Log.processed.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(1)
      MailyHerald::Log.skipped.count.should eq(0)
      MailyHerald::Log.error.count.should eq(0)

      @sequence.pending_mailings(@entity).first.should eq(@sequence.mailings[1])
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      MailyHerald::Log.processed.count.should eq(2)
      MailyHerald::Log.delivered.count.should eq(1)
      MailyHerald::Log.skipped.count.should eq(1)
      MailyHerald::Log.error.count.should eq(0)

      @sequence.pending_mailings(@entity).first.should eq(@sequence.mailings[2])
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      MailyHerald::Log.processed.count.should eq(3)
      MailyHerald::Log.delivered.count.should eq(2)
      MailyHerald::Log.skipped.count.should eq(1)
      MailyHerald::Log.error.count.should eq(0)
    end

    pending "should skip mailings with errors and create logs for them" do
      @sequence.mailings[1].update_attribute(:template, "foo {{error =! here bar")

      @sequence.pending_mailings(@entity).first.should eq(@sequence.mailings.first)
      @sequence.processable?(@entity).should be_truthy
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      MailyHerald::Log.processed.count.should eq(1)
      MailyHerald::Log.delivered.count.should eq(1)
      MailyHerald::Log.skipped.count.should eq(0)
      MailyHerald::Log.error.count.should eq(0)

      @sequence.pending_mailings(@entity).first.should eq(@sequence.mailings[1])
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      MailyHerald::Log.processed.count.should eq(2)
      MailyHerald::Log.delivered.count.should eq(1)
      MailyHerald::Log.skipped.count.should eq(0)
      MailyHerald::Log.error.count.should eq(1)

      @sequence.pending_mailings(@entity).first.should eq(@sequence.mailings[2])
      Timecop.freeze @entity.created_at + @sequence.pending_mailings(@entity).first.absolute_delay
      @sequence.run
      MailyHerald::Log.processed.count.should eq(3)
      MailyHerald::Log.delivered.count.should eq(2)
      MailyHerald::Log.skipped.count.should eq(0)
      MailyHerald::Log.error.count.should eq(1)
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
      @sequence.start_at.should eq("")
      @sequence = @sequence.subscription_for @entity
      @sequence.last_processing_time(@entity).should be_nil
      @sequence.next_processing_time(@entity).should be_nil

      Timecop.freeze @entity.created_at
      @sequence.run

      @sequence = @sequence.subscription_for @entity
      @sequence.last_processing_time(@entity).should be_nil
      @sequence.next_processing_time(@entity).should be_nil
    end

    pending "should allow to set start date via text field" do
      datetime = "2013-01-01 10:11"

      @sequence.start_at = datetime
      @sequence.should be_valid
      @sequence.start_at.should eq(datetime)

      @sequence.start_at = ""
      @sequence.should be_valid
    end
  end

  #describe "Without autosubscribe" do
    #before(:each) do
      #@sequence.update_attribute(:autosubscribe, false)
      #@sequence.should be_valid
      #@sequence.save.should be_truthy
      #@entity = FactoryGirl.create :user
    #end

    #after(:each) do
      #@sequence.update_attribute(:autosubscribe, true)
    #end

    #it "should create inactive subscription" do
      #subscription = @sequence.subscription_for @entity

      #MailyHerald::MailingSubscription.count.should eq(0)
      #MailyHerald::SequenceSubscription.count.should eq(1)
      #MailyHerald::Log.count.should eq(0)

      #Timecop.freeze @entity.created_at

      #@sequence.run

      #MailyHerald::MailingSubscription.count.should eq(0)
      #MailyHerald::SequenceSubscription.count.should eq(1)
      #MailyHerald::Log.count.should eq(0)
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

      subscription.should be_active

      next_processing = @sequence.next_processing_time(@entity)

      subscription.deactivate!
      subscription.should_not be_active

      @sequence.logs(@entity).count.should eq(0)
      @sequence.last_processing_time(@entity).should be_nil

      Timecop.freeze next_processing

      @sequence.run

      @sequence.logs(@entity).count.should eq(0)
      @sequence.last_processing_time(@entity).should be_nil

      @sequence.update_attribute(:override_subscription, true)

      @sequence.run

      @sequence.logs(@entity).count.should eq(1)
      @sequence.last_processing_time(@entity).to_i.should eq(next_processing.to_i)
    end
  end

end
