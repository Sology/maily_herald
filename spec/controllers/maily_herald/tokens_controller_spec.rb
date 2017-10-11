require 'rails_helper'

describe MailyHerald::TokensController do

  routes { MailyHerald::Engine.routes }

  let!(:entity) { create :user }
  let!(:mailing) { create :generic_one_time_mailing }
  let(:subscription) { mailing.subscription_for entity }

  before { mailing.list.subscribe! entity }

  it { expect(subscription.active?).to be_truthy }

  describe "GET #get" do
    context "with valid token" do
      before { get :get, params: {token: subscription.token} }

      it { subscription.reload; expect(subscription.active?).to be_falsy }
      it { expect(response).to redirect_to('/') }
      it { expect(flash[:notice]).to eq(I18n.t('maily_herald.subscription.deactivated')) }
    end

    context "with invalid token" do
      before { get :get, params: {token: "invalid_token"} }

      it { subscription.reload; expect(subscription.active?).to be_truthy }
      it { expect(response).to redirect_to('/') }
      it { expect(flash[:notice]).to eq(I18n.t('maily_herald.subscription.undefined_token')) }
    end
  end

end
