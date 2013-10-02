require 'spec_helper'

describe MailyHerald::MailingSubscription do
  before(:each) do
    @entity = FactoryGirl.create :user
    @mailing = MailyHerald.one_time_mailing :test_mailing
    @subscription = @mailing.subscription_for @entity
  end

  describe "Associations" do
    it {should belong_to(:entity)}
    it {should belong_to(:mailing)}

    it "should have valid associations" do
      @subscription.entity.should eq(@entity)
      @subscription.mailing.should eq(@mailing)
      @subscription.should be_valid
      @mailing.autosubscribe?.should be_true
      @subscription.should_not be_a_new_record
    end
  end

  describe "Template rendering" do
    it "should produce output" do
      @subscription.mailing.stub(:template).and_return("test {{user.name}}")
      @subscription.render_template.should eq("test #{@entity.name}")
    end

    it "should validate syntax" do
      @subscription.mailing.stub(:template).and_return("{% if 1 =! 2 %}ok{% endif %}")
      expect {@subscription.render_template}.to raise_error
    end
  end

  describe "Without autosubscribe" do
    before(:each) do
      @mailing.update_attribute(:autosubscribe, false)
      @entity = FactoryGirl.create :user
      @subscription = @mailing.subscription_for @entity
    end

    after(:each) do
      @mailing.update_attribute(:autosubscribe, true)
    end

    it "should initialize token" do
      @mailing.autosubscribe.should be_false
      @subscription.should_not be_active
      @subscription.activate!
      @subscription.should be_active
    end
  end
end
