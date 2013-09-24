require 'spec_helper'

describe MailyHerald::Log do
  before(:each) do
    @mailing = MailyHerald.periodical_mailing(:weekly_summary)
    @entity = FactoryGirl.create :user
  end

  describe "Associations" do
    it {should belong_to(:entity)}
    it {should belong_to(:mailing)}

    it "should have proper scopes" do
      log = MailyHerald::Log.create_for @mailing, @entity
      log.should be_valid
      log.entity.should eq(@entity)
      log.mailing.should eq(@mailing)

      MailyHerald::Log.for_entity(@entity).should include(log)
      MailyHerald::Log.for_mailing(@mailing).should include(log)

      MailyHerald::Log.for_entity(@entity).for_mailing(@mailing).last.should eq(log)
    end
  end

  describe "Validations" do
    it {should validate_presence_of(:entity)}
    it {should validate_presence_of(:mailing)}
  end

  it "should have proper scopes" do
    log1 = MailyHerald::Log.create_for @mailing, @entity
    log2 = MailyHerald::Log.create_for @mailing, @entity
    MailyHerald::Log.count.should eq(2)

    log1.update_attribute(:status, :skipped)
    MailyHerald::Log.count.should eq(2)
    MailyHerald::Log.skipped.count.should eq(1)

    log1.update_attribute(:status, :error)
    MailyHerald::Log.count.should eq(2)
    MailyHerald::Log.error.count.should eq(1)
  end
end
