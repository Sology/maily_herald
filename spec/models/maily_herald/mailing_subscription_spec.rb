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
end
