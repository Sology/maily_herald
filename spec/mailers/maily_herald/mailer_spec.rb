require 'rails_helper'

describe MailyHerald::Mailer do

  let!(:entity) { create :user }
  let!(:mailing) { create :ad_hoc_mailing }
  let!(:list) { mailing.list }
  
  it { expect(MailyHerald::Log.delivered.count).to eq(0) }

  context "without subscription" do
    before { AdHocMailer.ad_hoc_mail(entity).deliver }

    pending { expect(MailyHerald::Log.delivered.count).to eq(0) }
  end

  context "with subscription" do
    before do
      list.subscribe! entity
      AdHocMailer.ad_hoc_mail(entity).deliver
    end

    pending { expect(MailyHerald::Log.delivered.count).to eq(1) }
  end

  context "without defined mailing" do
    pending { expect { AdHocMailer.missing_mailing_mail(entity).deliver }.not_to change { ActionMailer::Base.deliveries.count } }
  end

end
