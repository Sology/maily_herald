require 'spec_helper'

describe MailyHerald::Sequence do
  describe "Validations" do
    it {should validate_presence_of(:context_name)}
    it {should validate_presence_of(:name)}
    it {should validate_presence_of(:mode)}
  end

  describe "Chronological" do
    before(:each) do
      @sequence = MailyHerald.sequence(:newsletters)
      @sequence.should be_a MailyHerald::Sequence
      @sequence.should_not be_a_new_record
    end

    describe "Associations" do
      it {should have_many(:records)}
      it {should have_many(:mailings)}

      it "should have valid 'through' associations" do
        @sequence.mailings.length.should_not be_zero
      end
    end

    describe "Records" do
      before(:each) do
        @entity = FactoryGirl.create :user
      end

      it "should find or initialize sequence record" do
        record = @sequence.find_or_initialize_record_for @entity
        record.should be_a_new_record
        record.save.should be_true

        record = @sequence.find_or_initialize_record_for @entity
        record.should_not be_a_new_record
      end
    end

    describe "Condition evaluation" do
      before(:each) do
        @entity = FactoryGirl.create :user
      end

      it "should parse start_var" do
        @entity.should be_a(User)
        @sequence.evaluate_start_var_for(@entity).should be_a(Time)
      end
    end

    describe "Delivery" do
      before(:each) do
        @entity = FactoryGirl.create :user
      end

      it "should deliver mailings from chronological sequence" do
        @sequence.mailings.length.should eq(2)
        @sequence.delivered_mailings_for(@entity).length.should eq(0)
        @sequence.pending_mailings_for(@entity).length.should eq(2)

        @sequence.run
        MailyHerald::SequenceRecord.count.should eq(0)
        MailyHerald::MailingRecord.count.should eq(0)

        Timecop.freeze(@entity.created_at + 1.hour + 10.minutes) do
          @sequence.run
          MailyHerald::SequenceRecord.count.should eq(1)
          MailyHerald::MailingRecord.count.should eq(0)

          seq_record = @sequence.record_for(@entity)
          seq_record.should_not be_nil
          seq_record.entity.should eq(@entity)
        end

        @sequence.delivered_mailings_for(@entity).length.should eq(1)
        @sequence.pending_mailings_for(@entity).length.should eq(1)

        Timecop.freeze(@entity.created_at + 2.hour + 10.minutes) do
          @sequence.run
          MailyHerald::SequenceRecord.count.should eq(1)
          MailyHerald::MailingRecord.count.should eq(0)
        end

        @sequence.delivered_mailings_for(@entity).length.should eq(2)
        @sequence.pending_mailings_for(@entity).length.should eq(0)
      end
    end
  end

  describe "Periodical" do
    before(:each) do
      @sequence = MailyHerald.sequence(:statistics)
      @sequence.should be_a MailyHerald::Sequence
      @sequence.should_not be_a_new_record
    end

    it "should deliver mailings from periodical sequence" do
    end
  end
end
