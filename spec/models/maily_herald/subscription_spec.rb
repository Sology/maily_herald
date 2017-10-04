require 'spec_helper'

describe MailyHerald::Subscription do
  before(:each) do
    @entity = FactoryGirl.create :user
    @mailing = MailyHerald.one_time_mailing :test_mailing
    @list = @mailing.list

    @subscription = @list.subscribe! @entity
  end

  describe "Associations" do
    it "should have valid associations" do
      expect(@subscription.entity).to eq(@entity)
      expect(@subscription.list).to eq(@list)
      expect(@subscription).to be_valid
      expect(@subscription).not_to be_a_new_record
    end
  end

  describe "Template rendering" do
    it "should produce output" do
      @mailing.stub(:template).and_return("test {{user.name}}")
      expect(@mailing.render_template(@entity)).to eq("test #{@entity.name}")
    end

    it "should validate syntax" do
      @mailing.stub(:template).and_return("{% if 1 =! 2 %}ok{% endif %}")
      expect {@mailing.render_template(@entity)}.to raise_error
    end
  end

  it "should instantiate subscription object from joined attributes" do
    list = MailyHerald.list(:generic_list)
    list.subscribe!(@entity)

    entity = list.subscribers.first

    expect(entity).to be_a(User)
    expect(entity).to have_attribute(:maily_subscription_id)
    expect(entity.maily_subscription_active).to be_truthy

    subscription = MailyHerald::Subscription.get_from(entity)

    expect(subscription).to be_a(MailyHerald::Subscription)
    expect(subscription).to be_readonly
    expect(subscription).to be_active
  end
end
