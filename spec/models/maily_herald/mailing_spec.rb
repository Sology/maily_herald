require 'rails_helper'

describe MailyHerald::Mailing do

  context "scope" do
    context "search_by" do
      let!(:mailing) { create :ad_hoc_mailing }

      it { expect(described_class.count).to eq(2) }

      context "when query is 'her'" do
        let(:scoped) { described_class.search_by("hoc") }

        it { expect(scoped.count).to eq(1) }
        it { expect(scoped.first.name).to eq("ad_hoc_mail") }
      end
    end
  end

  context "validations" do
    let!(:mailing) { create :generic_one_time_mailing }

    it { expect(mailing).to be_valid }

    it "should validate template_plain syntax" do
      mailing.template_plain = "foo {{ bar"
      expect(mailing).not_to be_valid
      expect(mailing.errors.messages.keys).to include(:template_plain)
      expect(mailing.errors.messages[:template_plain]).not_to be_empty
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
