require 'spec_helper'

describe MailyHerald do
  describe "setup" do
    before(:each) do
      @user = FactoryGirl.create :user
    end

    it "should extend context entity models" do
      MailyHerald.context(:all_users).model.name.should eq(User.name)
      User.included_modules.should include(MailyHerald::ModelExtensions)

      expect(@user).to respond_to(:maily_herald_subscriptions)
      expect(@user.maily_herald_subscriptions.length).to eq(0)
    end

    it "should create mailings from initializer" do
      mailing = MailyHerald.one_time_mailing(:test_mailing)
      expect(mailing).to be_kind_of(MailyHerald::Mailing)
      expect(mailing).not_to be_a_new_record
    end

    it "should create sequences from initializer" do
      sequence = MailyHerald.sequence(:newsletters)
      expect(sequence).to be_kind_of(MailyHerald::Sequence)
      expect(sequence).not_to be_a_new_record

      expect(sequence.mailings.length).to eq(3)
    end
  end
end
