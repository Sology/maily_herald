require 'spec_helper'

describe MailyHerald::Mailing do
  describe "Validations" do
    it {should validate_presence_of(:name)}
    it {should validate_presence_of(:title)}

    it "should validate template syntax" do
      @mailing = MailyHerald.one_time_mailing :test_mailing
      @mailing.should be_valid
      @mailing.template = "foo {{ bar"
      @mailing.should_not be_valid
      @mailing.errors.messages.keys.should include(:template)
      @mailing.errors.messages[:template].should_not be_empty
    end

    it "should validate conditions syntax" do
      @mailing = MailyHerald.one_time_mailing :test_mailing
      @mailing.should be_valid
      @mailing.conditions = "foo {{ bar"
      @mailing.should_not be_valid
      @mailing.errors.messages.keys.should include(:conditions)
      @mailing.errors.messages[:conditions].should_not be_empty
    end
  end

  describe "Associations" do
    it {should have_many(:subscriptions)}
  end
end
