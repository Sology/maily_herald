require 'spec_helper'

describe MailyHerald::Log do
  before(:each) do
    @mailing = MailyHerald.periodical_mailing(:weekly_summary)
    @entity = FactoryGirl.create :user
  end

  describe "Associations" do
    it "should have proper scopes" do
      log = MailyHerald::Log.create_for @mailing, @entity, {status: :delivered}
      expect(log).to be_valid
      expect(log.entity).to eq(@entity)
      expect(log.mailing).to eq(@mailing)

      expect(MailyHerald::Log.for_entity(@entity)).to include(log)
      expect(MailyHerald::Log.for_mailing(@mailing)).to include(log)

      expect(MailyHerald::Log.for_entity(@entity).for_mailing(@mailing).last).to eq(log)
    end
  end

  it "should have proper scopes" do
    log1 = MailyHerald::Log.create_for @mailing, @entity, {status: :delivered}
    log2 = MailyHerald::Log.create_for @mailing, @entity, {status: :delivered}
    expect(MailyHerald::Log.count).to eq(2)

    log1.update_attribute(:status, :skipped)
    expect(MailyHerald::Log.count).to eq(2)
    expect(MailyHerald::Log.skipped.count).to eq(1)

    log1.update_attribute(:status, :error)
    expect(MailyHerald::Log.count).to eq(2)
    expect(MailyHerald::Log.error.count).to eq(1)
  end
end
