require 'rails_helper'

describe MailyHerald::List do

  describe "Initial" do
    let!(:entity) { create :user }
    let!(:product) { create :product }
    let(:list) { MailyHerald.list(:generic_list) }
    let(:list2) { MailyHerald::List.new }

    before do
      list2.context_name = :all_users
      list2.name = "another_list"

      expect(list).to be_kind_of(MailyHerald::List)
      expect(list2.save).to be_truthy
    end

    after { list2.destroy }

    context "subscripions" do
      context "subscribing" do
        it { expect(list.subscribed?(entity)).to be_falsy }
        it { expect(list.subscribe!(entity)).to be_kind_of(MailyHerald::Subscription) }
        it { list.subscribe!(entity); expect(list.subscribed?(entity)).to be_truthy }
        it { expect(list.unsubscribe!(entity)).to be_kind_of(MailyHerald::Subscription) }
        it { expect(list.subscribed?(entity)).to be_falsy }
        it { expect{list.subscribe! product}.to raise_error(ActiveRecord::RecordInvalid) }
      end

      context "returning valid subscribers" do
        it { expect(list.subscribers).to be_empty }
        it { expect(list2.subscribers).to be_empty }
        it { expect(list.potential_subscribers).to include(entity) }
        it { list.subscribe!(entity); expect(list.subscribers.first).to eq(entity) }
        it { list.subscribe!(entity); expect(list.potential_subscribers).to be_empty }
        it { expect(list2.subscribers).to be_empty }
        it { expect(list2.potential_subscribers.first).to eq(entity) }
      end
    end

    context "list logs" do
      it "should fetch all logs for list" do
        list.subscribe!(entity)
        expect(list.subscribers.first).to eq(entity)

        mailing = MailyHerald.one_time_mailing(:test_mailing)
        mailing.run

        expect(list.logs).to include(mailing.logs.first)
      end
    end

    context "lockable" do
      it { expect(list).to be_locked }

      it "should NOT alter lsit attributes" do
        list.title = "foo"
        expect(list.save).to be_falsy
        expect(list.errors.messages).to include(:base)
      end

      it "should NOT be destroyed" do
        list.destroy
        expect(list).not_to be_destroyed
      end
    end
  end

end
