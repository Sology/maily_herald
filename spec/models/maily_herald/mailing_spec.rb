require 'rails_helper'

describe MailyHerald::Mailing do

  context "validations" do
    let!(:mailing) { create :test_mailing }

    it { expect(mailing).to be_valid }

    it "should validate template syntax" do
      mailing.template = "foo {{ bar"
      expect(mailing).not_to be_valid
      expect(mailing.errors.messages.keys).to include(:template)
      expect(mailing.errors.messages[:template]).not_to be_empty
    end

    it "should validate conditions syntax" do
      mailing.conditions = "foo {{ bar"
      expect(mailing).not_to be_valid
      expect(mailing.errors.messages.keys).to include(:conditions)
      expect(mailing.errors.messages[:conditions]).not_to be_empty
    end
  end
  
  context "locking" do
    let!(:mailing) { MailyHerald.one_time_mailing :locked_mailing }

    it { expect(mailing).to be_locked }

    it "should produce validation errors" do
      mailing.title = "foo"
      expect(mailing).not_to be_valid
      expect(mailing.errors.messages).to include(:base)
    end

    it "should NOT allow to destroy locked mailing" do
      mailing.destroy
      expect(mailing).not_to be_destroyed
    end
  end

end
