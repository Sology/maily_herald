require 'rails_helper'

describe MailyHerald::AdHocMailing do

  let!(:entity) { create :user }
  let!(:list) { MailyHerald.list :generic_list }
  let!(:mailing) { create :ad_hoc_mailing }

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
          pending { expect(ret.first).to be_delivered }
          pending { expect(ret.first.mail).to be_kind_of(Mail::Message) }
          it { ret; expect(MailyHerald::Subscription.count).to eq(1) }
          pending { ret; expect(MailyHerald::Log.delivered.count).to eq(1) }

          pending "log should have proper values" do
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
        pending { expect(msg).to be_kind_of(Mail::Message) }
        pending { msg; expect(MailyHerald::Log.delivered.count).to eq(1) }
        pending { msg; expect(MailyHerald::Log.delivered.first.entity).to eq(entity) }
      end

      context "with explicit scheduling" do
        before { mailing.schedule_delivery_to entity, Time.now - 5 }

        context "subscription active" do
          pending { expect(msg).to be_kind_of(Mail::Message) }
          pending { msg; expect(MailyHerald::Log.delivered.count).to eq(1) }
        end

        context "subscription inactive" do
          before { list.unsubscribe!(entity) }

          pending { msg; expect(MailyHerald::Log.delivered.count).to eq(0)}
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

  context "with subscription override" do
    before { mailing.update_attributes!(override_subscription: true) }
    after  { mailing.update_attributes!(override_subscription: false) }

    it { expect(MailyHerald::Log.delivered.count).to eq(0) }
    it { expect(mailing.override_subscription?).to be_truthy }
    it { expect(mailing.enabled?).to be_truthy }

    context "single mail should be delivered" do
      let(:msg) { AdHocMailer.ad_hoc_mail(entity).deliver }

      before { mailing.schedule_delivery_to entity, Time.now - 5 }

      pending { expect(msg).to be_kind_of(Mail::Message) }
      pending { msg; expect(MailyHerald::Log.delivered.count).to eq(1)}
    end
  end

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
