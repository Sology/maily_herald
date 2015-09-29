require 'spec_helper'

describe MailyHerald::List do
  before(:each) do
    @entity = FactoryGirl.create :user
    @product = FactoryGirl.create :product

    @list = MailyHerald.list(:generic_list)
    @list2 = MailyHerald::List.new
    @list2.context_name = :all_users
    @list2.name = "another_list"

    expect(@list).to be_kind_of(MailyHerald::List)
    expect(@list2.save).to be_truthy
  end

  after(:each) do
    @list2.destroy
  end

  it "should handle subscripions" do
    expect(@list.subscribed?(@entity)).to be_falsy
    expect(@list.subscribe!(@entity)).to be_kind_of(MailyHerald::Subscription)
    expect(@list.subscribed?(@entity)).to be_truthy
    expect(@list.unsubscribe!(@entity)).to be_kind_of(MailyHerald::Subscription)
    expect(@list.subscribed?(@entity)).to be_falsy
  end

  it "should not allow other models" do
    @list.subscribe! @entity
    expect(@list.subscribed?(@entity)).to be_truthy
    expect{@list.subscribe! @product}.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "should return valid subscribers" do
    expect(@list.subscribers).to be_empty
    expect(@list2.subscribers).to be_empty

    expect(@list.subscribe!(@entity)).to be_kind_of(MailyHerald::Subscription)
    expect(@list.subscribers.first).to eq(@entity)
    expect(@list.potential_subscribers).to be_empty
    expect(@list2.subscribers).to be_empty
    expect(@list2.potential_subscribers.first).to eq(@entity)
  end

  it "should fetch all logs for list" do
    @list.subscribe!(@entity)
    expect(@list.subscribers.first).to eq(@entity)

    @mailing = MailyHerald.one_time_mailing(:test_mailing)
    @mailing.run

    expect(@list.logs).to include(@mailing.logs.first)
  end

  it "should be lockable" do
    @list = MailyHerald.list :generic_list
    expect(@list).to be_locked
    @list.title = "foo"
    expect(@list.save).to be_falsy
    expect(@list.errors.messages).to include(:base)
    @list.destroy
    expect(@list).not_to be_destroyed
  end
end
