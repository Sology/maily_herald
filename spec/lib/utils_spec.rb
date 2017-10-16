require 'rails_helper'

describe MailyHerald::Utils do

  describe MailyHerald::Utils::MarkupEvaluator do

    let!(:entity) { create :user }
    let!(:mailing) { create :generic_one_time_mailing }
    let(:list) { mailing.list }
    let(:subscription) { mailing.subscription_for entity }
    let(:evaluator) { described_class.new(list.context.drop_for(entity, subscription)) }

    before { list.subscribe! entity }

    context "conditions" do
      it { expect(mailing).to be_valid }

      context "syntax" do
        before { mailing.conditions = "foo bar" }

        it { expect(described_class.test_conditions(mailing.conditions)).to be_falsy }
        it { expect(mailing).not_to be_valid }
        it { mailing.valid?; expect(mailing.errors).to include(:conditions) }
      end

      context "numerical" do
        context "integer" do
          before { mailing.conditions = "2" }
          it { expect {mailing.conditions_met?(entity)}.to raise_error(ArgumentError) }
        end

        context "true condition" do
          before { mailing.conditions = "5 == 5" }
          it { expect(evaluator.evaluate_conditions(mailing.conditions)).to be_truthy }
          it { expect {mailing.conditions_met?(entity)}.not_to raise_error }
        end

        context "false condition" do
          before { mailing.conditions = "2 == 3" }
          it { expect(evaluator.evaluate_conditions(mailing.conditions)).to be_falsy }
          it { expect {mailing.conditions_met?(entity)}.not_to raise_error }
        end
      end

      context "more complex" do
        it { expect(entity.weekly_notifications).to be_truthy }
      
        context "check if true" do
          before { mailing.conditions = "user.weekly_notifications == true" }
          it { expect(evaluator.evaluate_conditions(mailing.conditions)).to be_truthy }
          it { expect {mailing.conditions_met?(entity)}.not_to raise_error }
        end
      
        context "check if false" do
          before { mailing.conditions = "user.weekly_notifications == false" }
          it { expect(evaluator.evaluate_conditions(mailing.conditions)).to be_falsy }
          it { expect {mailing.conditions_met?(entity)}.not_to raise_error }
        end

        context "update to false and check if true" do
          before do
            entity.update_attributes! weekly_notifications: false
            expect(entity.weekly_notifications).to be_falsy
            mailing.conditions = "user.weekly_notifications == true"
          end

          it { expect(evaluator.evaluate_conditions(mailing.conditions)).to be_falsy }
          it { expect {mailing.conditions_met?(entity)}.not_to raise_error }
        end
      end
    end

    context "start_at" do
      context "validate syntax" do
        before { mailing.start_at = "- foo bar | ddd" }

        it { expect(described_class.test_start_at(mailing.start_at)).to be_falsy }
        it { expect(mailing).not_to be_valid }
        it { mailing.valid?; expect(mailing.errors).to include(:start_at) }
      end

      context "evaluate without filters" do
        it { expect(evaluator.evaluate_start_at("user.created_at")).to eq(entity.created_at) }
      end

      context "evaluate with filters" do
        it { expect(evaluator.evaluate_start_at("user.created_at | minus: 1, 'day'")).to eq(entity.created_at - 1.day) }
        it { expect(evaluator.evaluate_start_at("user.created_at | plus: 2, 'minutes'")).to eq(entity.created_at + 2.minutes) }
      end

      context "evaluate without subscription" do
        let!(:evaluator) { described_class.new(list.context.drop_for(entity, nil)) }
        it { expect(evaluator.evaluate_start_at("user.created_at")).to eq(entity.created_at) }
      end
    end

  end

end
