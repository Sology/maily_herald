require 'rails_helper'

describe MailyHerald::Context do

  let!(:entity) { create :user }
  let!(:mailing) { create :test_mailing }
  let!(:list) { mailing.list }
  let!(:context) { list.context }

  it { expect(context.destination_for(entity)).to eq(entity.email) }
  it { expect(context.destination_attribute).to be_nil }

  context "with subscription" do
    let(:subscription) { mailing.subscription_for entity }
    let(:drop) { context.drop_for entity, subscription }

    before { list.subscribe! entity }

    it { expect(context).to be_kind_of(MailyHerald::Context) }
    it { expect(drop["user"]).to be_kind_of(MailyHerald::Context::Drop) }
    it { expect(drop["user"]["name"]).to eq(entity.name) }
    it { expect(drop["user"]["properties"]["prop1"]).to eq(entity.name[0]) }
    it { expect(drop["subscription"]).to be_kind_of(MailyHerald::Subscription) }
  end

end
