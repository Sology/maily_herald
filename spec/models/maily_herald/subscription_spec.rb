require 'rails_helper'

describe MailyHerald::Subscription do

  let(:entity) { create :user }
  let(:mailing) { create :generic_one_time_mailing }
  let(:list) { mailing.list }
  let!(:subscription) { list.subscribe! entity }

  context "associations" do
    it { expect(subscription.entity).to eq(entity) }
    it { expect(subscription.list).to eq(list) }
    it { expect(subscription).to be_valid }
    it { expect(subscription).not_to be_a_new_record }
  end

  context "template rendering" do
    context "valid template_plain" do
      before { expect(mailing).to receive(:template_plain).and_return("test {{user.name}}") }
      it { expect(mailing.render_template(entity)).to eq("test #{entity.name}") }
    end

    context "invalid template_plain" do
      before { expect(mailing).to receive(:template_plain).and_return("{% if 1 =! 2 %}ok{% endif %}") }
      it { expect{mailing.render_template(entity)}.to raise_error(Liquid::ArgumentError) }
    end
  end

  context "instantiation subscription object from joined attributes" do
    let!(:list) {MailyHerald.list :generic_list }

    before { list.subscribe!(entity) }
    subject { list.subscribers.first }

    it { expect(subject).to be_a(User) }
    it { expect(subject).to have_attribute(:maily_subscription_id) }
    it { expect(subject.maily_subscription_active).to be_truthy }

    it "should be readonly and active" do
      subscription = MailyHerald::Subscription.get_from(subject)

      expect(subscription).to be_a(MailyHerald::Subscription)
      expect(subscription).to be_readonly
      expect(subscription).to be_active
    end
  end

end
