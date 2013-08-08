require 'spec_helper'

describe MailyHerald do
  describe "setup" do
    before(:each) do
      @user = FactoryGirl.create :user
    end

    it "should extend context entity models" do
      User.included_modules.should include(MailyHerald::ModelExtensions::TriggerPatch)
      User.included_modules.should include(MailyHerald::ModelExtensions::AssociationsPatch)

      @user.should respond_to(:maily_herald_subscriptions)

      @user.maily_herald_subscriptions.length.should be_zero
    end

    it "should create mailings from initializer" do
      mailing = MailyHerald.one_time_mailing(:test_mailing)
      mailing.should be_a MailyHerald::Mailing
      mailing.should_not be_a_new_record
    end

    it "should create sequences from initializer" do
      sequence = MailyHerald.sequence(:newsletters)
      sequence.should be_a MailyHerald::Sequence
      sequence.should_not be_a_new_record

      sequence.mailings.length.should eq(3)
    end
  end
end
