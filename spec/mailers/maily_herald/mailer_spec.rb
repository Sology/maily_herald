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

  it "should handle missing mailer" do
    expect { TestMailer.sample_mail_error(@entity).deliver }.to raise_error
  end
end
