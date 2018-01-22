require 'rails_helper'
require 'mail'

describe MailyHerald::Log::DeliveryAttempts do

  let(:entity)  { create :user }
  let(:mailing) { create :ad_hoc_mailing }
  let!(:log)    { MailyHerald::Log.create_for mailing, entity, {status: :error} }
  let(:da)     { described_class.new log.data }

  describe "#list" do
    context "with empty list" do
      it { expect(da.list).to be_empty }
    end

    context "with some data" do
      before do
        log.data = {
          delivery_attempts: [
            {
              action:   :retry,
              reason:   :error,
              date_at:  Time.now,
              msg:      "test_error"
            }
          ]
        }
        log.save!
        log.reload
      end

      it { expect(da.list).not_to be_empty }
      it { expect(da.list.count).to eq(1) }
    end
  end

  describe "#add" do
    context "with empty list" do
      it "should add new hash to list" do
        da.add(:retry, :error, "test_error")
        expect(da.list).not_to be_empty
        expect(da.list.count).to eq(1)
        expect(da.list.first[:action]).to eq(:retry)
        expect(da.list.first[:reason]).to eq(:error)
        expect(da.list.first[:date_at]).to be_kind_of(Time)
        expect(da.list.first[:msg]).to eq("test_error")
      end
    end

    context "with some data" do
      before do
        log.data = {
          delivery_attempts: [
            {
              action:   :retry,
              reason:   :error,
              date_at:  Time.now,
              msg:      "test_error"
            }
          ]
        }
        log.save!
        log.reload
      end

      it "should add new hash to list" do
        da.add(:retry, :error, "test_error2")
        expect(da.list).not_to be_empty
        expect(da.list.count).to eq(2)
        expect(da.list.last[:action]).to eq(:retry)
        expect(da.list.last[:reason]).to eq(:error)
        expect(da.list.last[:date_at]).to be_kind_of(Time)
        expect(da.list.last[:date_at]).not_to eq(da.list.first[:date_at])
        expect(da.list.last[:msg]).to eq("test_error2")
      end
    end
  end

  describe "#count" do
    before do
      log.data = {
        delivery_attempts: [
          {
            action:   :retry,
            reason:   :error,
            date_at:  Time.now,
            msg:      "test_error"
          },
          {
            action:   :postpone,
            reason:   :not_processable,
            date_at:  Time.now,
            msg:      "Postponed by admin"
          }
        ]
      }
      log.save!
      log.reload
    end

    it { expect(da.count).to eq(2) }
    it { expect(da.count(:error)).to eq(1) }
    it { expect(da.count(:not_processable)).to eq(1) }
  end
end
