require 'spec_helper'

describe MailyHerald::SequenceMailing do
  before(:each) do
    @sequence = MailyHerald.sequence(:newsletters)
    @mailing = @sequence.mailings.first
  end

  describe "Validations" do
    it {should validate_presence_of(:relative_delay)}

    it do
      @mailing.relative_delay = nil
      @mailing.should_not be_valid

      @mailing.relative_delay = ""
      @mailing.should_not be_valid
    end
  end
end
