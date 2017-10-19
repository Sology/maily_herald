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

  describe "initial processing time calculation" do
    let(:mailing) { create :weekly_summary, start_at: start_at }
    let(:calculated_start_time) { subject.calculate_processing_time }

    context "with general scheduling" do
      context "in the past" do
        let(:start_at_time) { Time.now.round - 2.weeks - 1.day }
        let(:start_at) { start_at_time.to_s }

        it("should skip missed periods and start from next closest period") { expect(calculated_start_time).to eq(start_at_time + 3.weeks) }
      end

      context "in the future" do
        let(:start_at_time) { Time.now.round - 5.days }
        let(:start_at) { start_at_time.to_s }

        it("should start from the next closest period after start time") { expect(calculated_start_time).to eq(start_at_time + 1.week) }
      end
    end

    context "with individual scheduling" do
      context "in the past" do
        let(:start_at) { "user.created_at" }
        let(:entity) { create :user, created_at: Time.now.round - 2.weeks - 2.days }

        it("should start immediately") { expect(calculated_start_time).to eq(entity.created_at) }
      end
    end
  end
end
