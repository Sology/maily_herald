require 'rails_helper'

describe MailyHerald::TokensController do

  routes { MailyHerald::Engine.routes }

  let!(:entity) { create :user }
  let!(:mailing) { create :generic_one_time_mailing }
  let(:subscription) { mailing.subscription_for entity }

  before { mailing.list.subscribe! entity }

  it { expect(subscription.active?).to be_truthy }

  describe "GET #unsubscribe" do
    context "with valid token" do
      before { get :unsubscribe, params: {token: subscription.token} }

      it { subscription.reload; expect(subscription.active?).to be_falsy }
      it { expect(response).to redirect_to('/') }
      it { expect(flash[:notice]).to eq(I18n.t('maily_herald.subscription.deactivated')) }
    end

    context "with invalid token" do
      before { get :unsubscribe, params: {token: "invalid_token"} }

      it { subscription.reload; expect(subscription.active?).to be_truthy }
      it { expect(response).to redirect_to('/') }
      it { expect(flash[:notice]).to eq(I18n.t('maily_herald.subscription.undefined_token')) }
    end
  end

  describe "GET #open" do
    let(:log) { MailyHerald::Log.delivered.last }

    before { mailing.run && mailing.reload }

    it { expect(MailyHerald::Log.delivered.count).to eq(1) }
    it { expect(log.opens.list).to be_kind_of(Array) }
    it { expect(log.opens.list).to be_empty }

    context "with invalid token" do
      before do
        get :open, params: {token: "wrongOne"}, format: :gif
        log.reload
      end

      it { expect(response.status).to eq(200) }
      it { expect(response.header['Content-Type']).to eq("image/gif") }
      it { expect(log.opens.list).to be_kind_of(Array) }
      it { expect(log.opens.list).to be_empty }
    end

    context "with valid token" do
      before do
        get :open, params: {token: log.token}, format: :gif
        log.reload
      end

      it { expect(response.status).to eq(200) }
      it { expect(response.header['Content-Type']).to eq("image/gif") }
      it { expect(log.opens.list).not_to be_empty }
      it { expect(log.opens.list.count).to eq(1) }
      it { expect(log.opens.list.first[:ip_address]).to be_kind_of(String) }
      it { expect(log.opens.list.first[:user_agent]).to be_kind_of(String) }
      it { expect(log.opens.list.first[:opened_at]).to be_kind_of(Time) }

      context "open for the second time" do
        before do
          get :open, params: {token: log.token}, format: :gif
          log.reload
        end

        it { expect(response.status).to eq(200) }
        it { expect(response.header['Content-Type']).to eq("image/gif") }
        it { expect(log.opens.list.count).to eq(2) }
        it { expect(log.opens.list.last[:ip_address]).to be_kind_of(String) }
        it { expect(log.opens.list.last[:user_agent]).to be_kind_of(String) }
        it { expect(log.opens.list.last[:opened_at]).to be_kind_of(Time) }
      end
    end
  end

end
