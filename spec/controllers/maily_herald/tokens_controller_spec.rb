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

  describe "GET #open" do
    let(:log) { MailyHerald::Log.delivered.last }

    before { mailing.run && mailing.reload }

    it { expect(MailyHerald::Log.delivered.count).to eq(1) }
    it { expect(log.data[:opened_at]).to be_kind_of(Array) }
    it { expect(log.data[:opened_at]).to be_empty }
    it { expect(log.data[:ip_addresses]).to be_kind_of(Array) }
    it { expect(log.data[:ip_addresses]).to be_empty }

    context "with invalid token" do
      before do
        get :open, params: {token: "wrongOne"}, format: :gif
        log.reload
      end

      it { expect(response.status).to eq(200) }
      it { expect(response.header['Content-Type']).to eq("image/gif") }
      it { expect(log.data[:opened_at]).to be_kind_of(Array) }
      it { expect(log.data[:opened_at]).to be_empty }
      it { expect(log.data[:ip_addresses]).to be_kind_of(Array) }
      it { expect(log.data[:ip_addresses]).to be_empty }
    end

    context "with valid token" do
      before do
        get :open, params: {token: log.token}, format: :gif
        log.reload
      end

      it { expect(response.status).to eq(200) }
      it { expect(response.header['Content-Type']).to eq("image/gif") }
      it { expect(log.data[:opened_at]).not_to be_empty }
      it { expect(log.data[:opened_at].count).to eq(1) }
      it { expect(log.data[:opened_at].first).to be_kind_of(Time) }
      it { expect(log.data[:ip_addresses]).not_to be_empty }
      it { expect(log.data[:ip_addresses].count).to eq(1) }
      it { expect(log.data[:ip_addresses].first).to be_kind_of(String) }

      context "open for the second time" do
        before do
          get :open, params: {token: log.token}, format: :gif
          log.reload
        end

        it { expect(response.status).to eq(200) }
        it { expect(response.header['Content-Type']).to eq("image/gif") }
        it { expect(log.data[:opened_at]).not_to be_empty }
        it { expect(log.data[:opened_at].count).to eq(2) }
        it { expect(log.data[:opened_at].last).to be_kind_of(Time) }
        it { expect(log.data[:ip_addresses]).not_to be_empty }
        it { expect(log.data[:ip_addresses].count).to eq(2) }
        it { expect(log.data[:ip_addresses].last).to be_kind_of(String) }
      end
    end
  end

end
