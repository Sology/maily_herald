require 'spec_helper'

describe MailyHerald::Log do
  before(:each) do
    @mailing = MailyHerald.periodical_mailing(:weekly_summary)
    @entity = FactoryGirl.create :user
  end

  describe "Associations" do
    it "should have proper scopes" do
      log = MailyHerald::Log.create_for @mailing, @entity, {status: :delivered}
      log.should be_valid
      log.entity.should eq(@entity)
      log.mailing.should eq(@mailing)

      MailyHerald::Log.for_entity(@entity).should include(log)
      MailyHerald::Log.for_mailing(@mailing).should include(log)

      MailyHerald::Log.for_entity(@entity).for_mailing(@mailing).last.should eq(log)
    end
  end

  it "should have proper scopes" do
    log1 = MailyHerald::Log.create_for @mailing, @entity, {status: :delivered}
    log2 = MailyHerald::Log.create_for @mailing, @entity, {status: :delivered}
    expect(MailyHerald::Log.count).to eq(2)

    log1.update_attribute(:status, :skipped)
    MailyHerald::Log.count.should eq(2)
    MailyHerald::Log.skipped.count.should eq(1)

    log1.update_attribute(:status, :error)
    MailyHerald::Log.count.should eq(2)
    MailyHerald::Log.error.count.should eq(1)
  end
end
