require 'spec_helper'

describe MailyHerald::Mailing do
  describe "Validations" do
    it "should validate template syntax" do
      @mailing = MailyHerald.one_time_mailing :test_mailing
      expect(@mailing).to be_valid
      @mailing.template = "foo {{ bar"
      expect(@mailing).not_to be_valid
      expect(@mailing.errors.messages.keys).to include(:template)
      expect(@mailing.errors.messages[:template]).not_to be_empty
    end

    it "should validate conditions syntax" do
      @mailing = MailyHerald.one_time_mailing :test_mailing
      expect(@mailing).to be_valid
      @mailing.conditions = "foo {{ bar"
      expect(@mailing).not_to be_valid
      expect(@mailing.errors.messages.keys).to include(:conditions)
      expect(@mailing.errors.messages[:conditions]).not_to be_empty
    end
  end
  
  describe "Locking" do
    it "should produce valiadtion errors" do
      @mailing = MailyHerald.dispatch :locked_mailing
      expect(@mailing).to be_locked
      @mailing.title = "foo"
      expect(@mailing.save).to be_falsy
      expect(@mailing.errors.messages).to include(:base)
      @mailing.destroy
      expect(@mailing).not_to be_destroyed
    end
  end
end
