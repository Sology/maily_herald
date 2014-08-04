require 'spec_helper'

describe MailyHerald::List do
  before(:each) do
    @entity = FactoryGirl.create :user
    @list = MailyHerald.list(:generic_list)

    expect(@list).to be_kind_of(MailyHerald::List)
  end

  it "should handle subscripions" do
    expect(@list.subscribed?(@entity)).to be_falsy
    expect(@list.subscribe!(@entity)).to be_kind_of(MailyHerald::Subscription)
    expect(@list.subscribed?(@entity)).to be_truthy
    expect(@list.unsubscribe!(@entity)).to be_kind_of(MailyHerald::Subscription)
    expect(@list.subscribed?(@entity)).to be_falsy
  end
end
