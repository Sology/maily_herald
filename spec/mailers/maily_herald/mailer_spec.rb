require 'spec_helper'

describe MailyHerald::Mailer do
  before(:each) do
    @entity = FactoryGirl.create :user
  end

  it "should deliver" do
    MailyHerald::Log.count.should eq(0)

    TestMailer.sample_mail(@entity).deliver

    MailyHerald::Log.delivered.count.should eq(1)
  end

  pending "should handle missing mailer" do
  end
end
