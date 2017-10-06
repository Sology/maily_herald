require 'rails_helper'

describe MailyHerald::SequenceMailing do
  let!(:sequence) { create :newsletters }

  context "initial" do
    it { expect(sequence).to be_valid }
    it { expect(sequence).to be_persisted }
    it { expect(sequence.mailings).not_to be_empty }
    it { expect(sequence.mailings.count).to eq(3) }
  end

  context "validations" do
    let(:mailing) { sequence.mailings.first }

    context "invalid attributes - nil absolute_delay" do
      before { mailing.absolute_delay = nil }
      it { expect(mailing).not_to be_valid }
    end

    context "invalid attributes - blank absolute_delay" do
      before { mailing.absolute_delay = "" }
      it { expect(mailing).not_to be_valid }
    end
  end

end
