require 'rails_helper'

describe MailyHerald::AdHocMailing do

  let!(:entity) { create :user }
  let!(:mailing) { create :ad_hoc_mailing }
  let!(:list) { mailing.list }

  it { expect(list.context).to be_a(MailyHerald::Context) }

  context "with subscription" do
    before { list.subscribe!(entity) }

    it { expect(list.context.scope).to include(entity) }
    it { expect(mailing).to be_processable(entity) }
    it { expect(mailing).to be_enabled }

    context "run all delivery" do
      it { expect(mailing).to be_kind_of(MailyHerald::AdHocMailing) }
      it { expect(mailing).not_to be_a_new_record }

      it { expect(MailyHerald::Subscription.count).to eq(1) }
      it { expect(mailing.conditions_met?(entity)).to be_truthy }
      it { expect(mailing.processable?(entity)).to be_truthy }

      it { expect(mailing.logs.scheduled.count).to eq(0) }
      it { expect(mailing.logs.processed.count).to eq(0) }

      context "without explicit scheduling" do
        it "should NOT be delivered " do
          mailing.run
          expect(mailing.logs.scheduled.count).to eq(0)
          expect(mailing.logs.processed.count).to eq(0)
        end
      end

      context "with scheduling" do
        let!(:subscription) { mailing.subscription_for(entity) }

        before { mailing.schedule_delivery_to_all Time.now - 5 }

        it { expect(MailyHerald::Subscription.count).to eq(1) }
        it { expect(MailyHerald::Log.delivered.count).to eq(0) }
        it { expect(subscription).to be_kind_of(MailyHerald::Subscription) }
        it { expect(mailing.conditions_met?(entity)).to be_truthy }
        it { expect(mailing.processable?(entity)).to be_truthy }

        context "after running" do
          let(:ret) { mailing.run }

          it { expect(ret).to be_kind_of(Array) }
          it { expect(ret.first).to be_kind_of(MailyHerald::Log) }
          it { expect(ret.first).to be_delivered }
          it { expect(ret.first.mail).to be_kind_of(Mail::Message) }
          it { ret; expect(MailyHerald::Subscription.count).to eq(1) }
          it { ret; expect(MailyHerald::Log.delivered.count).to eq(1) }

          it "log should have proper values" do
            ret
            log = MailyHerald::Log.delivered.first
            expect(log.entity).to eq(entity)
            expect(log.mailing).to eq(mailing)
            expect(log.entity_email).to eq(entity.email)
          end
        end
      end
    end

    context "single entity delivery" do
      let(:msg) { AdHocMailer.ad_hoc_mail(entity).deliver }

      it { expect(mailing).to be_kind_of(MailyHerald::AdHocMailing) }
      it { expect(mailing).not_to be_a_new_record }
      it { expect(MailyHerald::Log.delivered.count).to eq(0) }

      context "without explicit scheduling" do
        it { expect(msg).to be_kind_of(Mail::Message) }
        it { msg; expect(MailyHerald::Log.delivered.count).to eq(1) }
        it { msg; expect(MailyHerald::Log.delivered.first.entity).to eq(entity) }
      end

      context "with explicit scheduling" do
        before { mailing.schedule_delivery_to entity, Time.now - 5 }

        context "subscription active" do
          it { expect(msg).to be_kind_of(Mail::Message) }
          it { msg; expect(MailyHerald::Log.delivered.count).to eq(1) }
        end

        context "subscription inactive" do
          before { list.unsubscribe!(entity) }

          it { msg; expect(MailyHerald::Log.delivered.count).to eq(0)}
        end
      end
    end

    context "with entity outside the scope" do
      before { entity.update_attributes!(active: false) }

      it { expect(list.context.scope).not_to include(entity) }
      it { expect(list).to be_subscribed(entity) }
      it { expect(mailing).not_to be_processable(entity) }
    end
  end

  pending "with runtime template errors should create error log"

  context "preview" do
    before { list.subscribe!(entity) }

    it { expect(mailing.logs).to be_empty }

    it "should not deliver" do
      mail = mailing.build_mail entity
      mailing.reload
      expect(mailing.logs).to be_empty
    end
  end

end
