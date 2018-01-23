require 'rails_helper'

describe MailyHerald::Mailer do

  let!(:entity) { create :user }
  let!(:mailing) { create :ad_hoc_mailing }
  let!(:list) { mailing.list }
  
  it { expect(MailyHerald::Log.delivered.count).to eq(0) }

  describe "delivery without explicit scheduling" do
    context "without subscription" do
      before { AdHocMailer.ad_hoc_mail(entity).deliver }

      it { expect(MailyHerald::Log.delivered.count).to eq(0) }
    end

    context "with subscription" do
      before do
        list.subscribe! entity
        AdHocMailer.ad_hoc_mail(entity).deliver
      end

      it { expect(MailyHerald::Log.delivered.count).to eq(1) }
    end

    context "without defined mailing" do
      it { expect { AdHocMailer.missing_mailing_mail(entity).deliver }.not_to change { ActionMailer::Base.deliveries.count } }
    end
  end
end
