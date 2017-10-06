require 'rails_helper'

describe MailyHerald do

  let!(:entity) { create :user }

  it { expect(MailyHerald.context(:all_users).model.name).to eq(User.name) }
  it { expect(User.included_modules).to include(MailyHerald::ModelExtensions) }
  it { expect(entity).to respond_to(:maily_herald_subscriptions) }
  it { expect(entity.maily_herald_subscriptions.length).to eq(0) }

  context "creating mailings" do
    let(:mailing) { create :test_mailing }

    it { expect(mailing).to be_kind_of(MailyHerald::Mailing) }
    it { expect(mailing).not_to be_a_new_record }
  end

  context "creating sequences" do
    let(:sequence) { create :newsletters }

    it { expect(sequence).to be_kind_of(MailyHerald::Sequence) }
    it { expect(sequence).not_to be_a_new_record }
    it { expect(sequence.mailings.length).to eq(3) }
  end

end
