require 'spec_helper'

describe MailyHerald::MailingRecord do
  describe "Associations" do
    before(:each) do
      @entity = FactoryGirl.create :user
      @mailing = MailyHerald.mailing :test_mailing
    end

    it {should belong_to(:entity)}
    it {should belong_to(:mailing)}

    it "should have valid associations" do
      record = @mailing.find_or_initialize_record_for @entity
      record.entity.should eq(@entity)
      record.mailing.should eq(@mailing)
      record.should be_valid
    end
  end
end
