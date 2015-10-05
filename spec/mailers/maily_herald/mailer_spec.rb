require 'spec_helper'

describe MailyHerald::Mailer do
  before(:each) do
    @entity = FactoryGirl.create :user
    @mailing = MailyHerald.dispatch(:ad_hoc_mail)
    @list = @mailing.list
  end

  context "without subscription" do
    it "should not deliver" do
      expect(MailyHerald::Log.delivered.count).to eq(0)

      AdHocMailer.ad_hoc_mail(@entity).deliver

      expect(MailyHerald::Log.delivered.count).to eq(0)
    end
  end

  context "with subscription" do
    before(:each) do
      @list.subscribe! @entity
    end

    it "should deliver" do
      expect(MailyHerald::Log.delivered.count).to eq(0)

      AdHocMailer.ad_hoc_mail(@entity).deliver

      expect(MailyHerald::Log.delivered.count).to eq(1)
    end
  end

  context "without defined mailing" do
    it "should not deliver" do
      expect do
        expect(MailyHerald::Log.delivered.count).to eq(0)

        AdHocMailer.missing_mailing_mail(@entity).deliver

        expect(MailyHerald::Log.delivered.count).to eq(0)
      end.not_to change { ActionMailer::Base.deliveries.count }
    end
  end
end
