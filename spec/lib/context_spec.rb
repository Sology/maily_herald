require 'rails_helper'

describe MailyHerald::Context do

  let!(:entity) { create :user }
  let!(:mailing) { create :generic_one_time_mailing }
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

  context "joined scope with subscription" do
    let!(:other_entity) { create :user }
    let(:subscription) { mailing.subscription_for entity }
    let(:drop) { context.drop_for entity, subscription }

    before { list.subscribe! entity }

    context "plain" do
      subject { context.scope_with_subscription(list, :outer) }

      it { expect(context).to be_kind_of(MailyHerald::Context) }
      it { expect(subject.length).to eq(2) }
      it { expect(subject).to include(entity) }
      it { expect(subject).to include(other_entity) }
      it { expect(subject.first.maily_subscription_id).to eq(subscription.id) }
    end
  end

  context "joined scope with logs" do
    let!(:other_entity) { create :user }
    let(:subscription) { mailing.subscription_for entity }

    let!(:log) { create(:log, entity: entity, mailing: mailing, status: "scheduled") }
    let!(:other_log) { create(:log, entity: other_entity, mailing: mailing, status: "delivered") }

    before { list.subscribe! entity }
    before { expect(User.count).to eq(2) }

    context "plain" do
      subject { context.scope_with_log(mailing, :outer) }

      it { expect(context).to be_kind_of(MailyHerald::Context) }
      it { expect(subject.length).to eq(2) }
      it { expect(subject).to include(entity) }
      it { expect(subject).to include(other_entity) }
      it { expect(subject.first.maily_log_id).to eq(log.id) }
      it { expect(subject.first.maily_subscription_id).to eq(subscription.id) }
    end

    context "with log conditions" do
      subject { context.scope_with_log(mailing, :outer, log_status: "scheduled") }

      it { expect(subject).to include(entity) }
      it { expect(subject).not_to include(other_entity) }
      it { expect(subject.first.maily_log_id).to eq(log.id) }
    end

    context "with other log conditions" do
      subject { context.scope_with_log(mailing, :outer, log_status: [nil, "scheduled"]) }

      let!(:another_entity) { create :user }

      it { expect(subject.length).to eq(2) }
      it { expect(subject).to include(entity) }
      it { expect(subject).to include(another_entity) }
      it { expect(subject).not_to include(other_entity) }
    end
  end
end
