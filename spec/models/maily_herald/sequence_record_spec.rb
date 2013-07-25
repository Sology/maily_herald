require 'spec_helper'

describe MailyHerald::SequenceRecord do
  before(:each) do
    @entity = FactoryGirl.create :user
    @sequence = MailyHerald.sequence :newsletters
  end

  describe "Associations" do
    it {should belong_to(:entity)}
    it {should belong_to(:sequence)}

    it "should have valid associations" do
      record = @sequence.find_or_initialize_record_for @entity
      record.entity.should eq(@entity)
      puts record.to_yaml
      record.sequence.should eq(@sequence)
      record.should be_valid
    end
  end

  describe "Operations" do
    it "should keep delivered mailings ids" do
      record = @sequence.find_or_initialize_record_for @entity
      record.save.should be_true

      record.delivered_mailings_ids.should be_empty
      record.add_delivered_mailing 1
      record.save

      record.reload
      record.delivered_mailings_ids.should include(1)
    end
  end
end
