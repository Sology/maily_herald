require 'spec_helper'

describe MailyHerald::DeliveryLog do
  before(:each) do
    @mailing = MailyHerald.periodical_mailing(:weekly_summary)
    @entity = FactoryGirl.create :user
  end

  describe "Associations" do
    it {should belong_to(:entity)}
    it {should belong_to(:mailing)}

    it "should have proper scopes" do
      log = MailyHerald::DeliveryLog.create_for @mailing, @entity
      log.should be_valid
      log.entity.should eq(@entity)
      log.mailing.should eq(@mailing)

      MailyHerald::DeliveryLog.for_entity(@entity).should include(log)
      MailyHerald::DeliveryLog.for_mailing(@mailing).should include(log)

      MailyHerald::DeliveryLog.for_entity(@entity).for_mailing(@mailing).last.should eq(log)
    end
  end

  describe "Validations" do
    it {should validate_presence_of(:entity)}
    it {should validate_presence_of(:mailing)}
  end
end
