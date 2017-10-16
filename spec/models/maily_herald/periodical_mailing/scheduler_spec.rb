require 'rails_helper'

describe MailyHerald::PeriodicalMailing::Scheduler do
  let(:mailing) { create :weekly_summary }
  let(:list) { mailing.list }
  let(:entity) { create :user }

  before { list.subscribe! entity }

  subject { described_class.new(mailing, entity) }

  describe "delivery at constant time, fix slight delays" do
    context "second delivery slightly after schedule" do
      let(:initial_processing_time) { (Time.current - 2.week).round }
      let(:second_processing_time) { (Time.current - 1.week + 1.day).round }
      let(:third_processing_time) { initial_processing_time + 2.weeks }
      let!(:initial_log) { mailing.logs.delivered.create(entity: entity, processing_at: initial_processing_time.round) }
      let!(:second_log) { mailing.logs.delivered.create(entity: entity, processing_at: second_processing_time.round) }

      it { expect(subject.start_processing_time).to eq(initial_processing_time) }
      it { expect(subject.calculate_processing_time).to eq(third_processing_time) }
    end

    context "second delivery way after schedule" do
      let(:initial_processing_time) { (Time.current - 2.week).round }
      let(:second_processing_time) { (Time.current - 1.week + 5.days).round }
      let(:third_processing_time) { initial_processing_time + 3.weeks }
      let!(:initial_log) { mailing.logs.delivered.create(entity: entity, processing_at: initial_processing_time.round) }
      let!(:second_log) { mailing.logs.delivered.create(entity: entity, processing_at: second_processing_time.round) }

      it { expect(subject.start_processing_time).to eq(initial_processing_time) }
      it { expect(subject.calculate_processing_time).to eq(third_processing_time) }
    end
  end
end
