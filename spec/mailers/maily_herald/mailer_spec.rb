require 'spec_helper'

describe MailyHerald::Mailer do
  before(:each) do
    @entity = FactoryGirl.create :user
    @mailing = MailyHerald.dispatch(:sample_mail)
    @list = @mailing.list
  end

  describe "without subscription" do
    it "should not deliver" do
      MailyHerald::Log.delivered.count.should eq(0)

      TestMailer.sample_mail(@entity).deliver

      MailyHerald::Log.delivered.count.should eq(0)
    end
  end

  describe "with subscription" do
    before(:each) do
      @list.subscribe! @entity
    end

    it "should deliver" do
      MailyHerald::Log.delivered.count.should eq(0)

      TestMailer.sample_mail(@entity).deliver

      MailyHerald::Log.delivered.count.should eq(1)
    end
  end

  it "should handle missing mailer" do
    expect { TestMailer.sample_mail_error(@entity).deliver }.to raise_error
  end
end
