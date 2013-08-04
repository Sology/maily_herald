require 'spec_helper'

describe MailyHerald::SequenceSubscription do
  before(:each) do
    @entity = FactoryGirl.create :user
    @sequence = MailyHerald.sequence :newsletters
  end

  describe "Associations" do
    it {should belong_to(:entity)}
    it {should belong_to(:sequence)}

    it "should have valid associations" do
      subscription = @sequence.subscription_for @entity
      subscription.entity.should eq(@entity)
      subscription.sequence.should eq(@sequence)
      subscription.should be_valid
    end
  end
end
