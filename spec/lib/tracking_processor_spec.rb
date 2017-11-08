require 'rails_helper'

describe MailyHerald::Tracking::Processor do

  let!(:entity) { create :user }

  context "without 'template_html'" do
    let!(:mailing) { create :custom_one_time_mailing }
    let(:log)      { MailyHerald::Log.delivered.first }

    before do
      mailing.list.subscribe! entity
      mailing.reload
      mailing.run
    end

    it { expect(MailyHerald::Log.delivered.count).to eq(1) }
    it { expect(MailyHerald::Log.delivered.last.data[:content].match(/gif/)).to be_nil }
  end

  context "with 'template_html'" do
    context "with generic mailer" do
      context "when 'track' is set to true" do
        let!(:mailing) { create :generic_one_time_mailing, kind: :html, template_html: "<h1>Hello</h1>" }
        let(:log)      { MailyHerald::Log.delivered.first }

        before do
          mailing.list.subscribe! entity
          mailing.reload
          mailing.run
        end

        it { expect(MailyHerald::Log.delivered.count).to eq(1) }
        it { expect(MailyHerald::Log.delivered.last.data[:content].match(/gif/)).not_to be_nil }
      end

      context "when 'track' is set to false" do
        let!(:mailing) { create :generic_one_time_mailing, kind: :html, template_html: "<h1>Hello</h1>", track: false }
        let(:log)      { MailyHerald::Log.delivered.first }

        before do
          mailing.list.subscribe! entity
          mailing.reload
          mailing.run
        end

        it { expect(MailyHerald::Log.delivered.count).to eq(1) }
        it { expect(MailyHerald::Log.delivered.last.data[:content].match(/gif/)).to be_nil }
      end
    end

    context "with custom mailer" do
      context "when 'track' is set to true" do
        let!(:mailing) { create :ad_hoc_mailing }
        let(:log)      { MailyHerald::Log.delivered.first }

        before do
          mailing.list.subscribe! entity
          mailing.schedule_delivery_to_all Time.now - 5
          mailing.reload
          mailing.run
        end

        it { expect(MailyHerald::Log.delivered.count).to eq(1) }
        it { expect(MailyHerald::Log.delivered.last.data[:content].match(/gif/)).not_to be_nil }
      end

      context "when 'track' is set to false" do
        let!(:mailing) { create :ad_hoc_mailing, track: false }
        let(:log)      { MailyHerald::Log.delivered.first }

        before do
          mailing.list.subscribe! entity
          mailing.schedule_delivery_to_all Time.now - 5
          mailing.reload
          mailing.run
        end

        it { expect(MailyHerald::Log.delivered.count).to eq(1) }
        it { expect(MailyHerald::Log.delivered.last.data[:content].match(/gif/)).to be_nil }
      end
    end
  end

end
