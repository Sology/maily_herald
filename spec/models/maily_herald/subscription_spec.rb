require 'spec_helper'

describe MailyHerald::Subscription do
  before(:each) do
    @entity = FactoryGirl.create :user
    @mailing = MailyHerald.one_time_mailing :test_mailing
    @list = @mailing.list

    @subscription = @list.subscribe! @entity
  end

  describe "Associations" do
    it "should have valid associations" do
      @subscription.entity.should eq(@entity)
      @subscription.list.should eq(@list)
      @subscription.should be_valid
      @subscription.should_not be_a_new_record
    end
  end

  describe "Template rendering" do
    it "should produce output" do
      @mailing.stub(:template).and_return("test {{user.name}}")
      expect(@mailing.render_template(@entity)).to eq("test #{@entity.name}")
    end

    it "should validate syntax" do
      @mailing.stub(:template).and_return("{% if 1 =! 2 %}ok{% endif %}")
      expect {@mailing.render_template(@entity)}.to raise_error
    end
  end
end
