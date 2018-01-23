require 'rails_helper'

describe MailyHerald::Log::Opens do
  let(:entity)  { create :user }
  let(:mailing) { create :ad_hoc_mailing }
  let!(:log)    { MailyHerald::Log.create_for mailing, entity, {status: :delivered} }
  let(:da)     { described_class.new log.data }

  describe "#list" do
    context "with empty list" do
      it { expect(da.list).to be_empty }
    end

    context "with some data" do
      before do
        log.data = {
          opens: [
            {
              ip_address: "192.168.1.1",
              user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.96 Safari/537.36",
              opened_at:  Time.zone.now
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
        da.add("192.168.1.2", "Mozilla/5.0")
        expect(da.list).not_to be_empty
        expect(da.list.count).to eq(1)
        expect(da.list.first[:ip_address]).to eq("192.168.1.2")
        expect(da.list.first[:user_agent]).to eq("Mozilla/5.0")
        expect(da.list.first[:opened_at]).to be_kind_of(Time)
      end
    end

    context "with some data" do
      before do
        log.data = {
          opens: [
            {
              ip_address: "192.168.1.1",
              user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.96 Safari/537.36",
              opened_at:  Time.zone.now - 1.minute
            }
          ]
        }
        log.save!
        log.reload
      end

      it "should add new hash to list" do
        da.add("192.168.1.2", "Mozilla/5.0")
        expect(da.list).not_to be_empty
        expect(da.list.count).to eq(2)
        expect(da.list.last[:ip_address]).to eq("192.168.1.2")
        expect(da.list.last[:user_agent]).to eq("Mozilla/5.0")
        expect(da.list.last[:opened_at]).to be_kind_of(Time)
        expect(da.list.last[:opened_at]).not_to eq(da.list.first[:opened_at])
      end
    end
  end

  describe "#count" do
    before do
      log.data = {
        opens: [
          {
            ip_address: "192.168.1.1",
            user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.96 Safari/537.36",
            opened_at:  Time.zone.now - 1.minute
          },
          {
            ip_address: "192.168.1.1",
            user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.96 Safari/537.36",
            opened_at:  Time.zone.now
          }
        ]
      }
      log.save!
      log.reload
    end

    it { expect(da.count).to eq(2) }
  end
end
