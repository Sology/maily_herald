require 'spec_helper'

describe MailyHerald::Utils do
  describe MailyHerald::Utils::MarkupEvaluator do
    before(:each) do
      @mailing = MailyHerald.one_time_mailing :test_mailing
      @user = FactoryGirl.create :user
      @list = @mailing.list
      @list.subscribe!(@user)
      @subscription = @mailing.subscription_for(@user)
      @evaluator = MailyHerald::Utils::MarkupEvaluator.new(@list.context.drop_for(@user, @subscription))
    end

    describe "conditions" do
      it "should validate syntax" do
        expect(@mailing).to be_valid
        @mailing.conditions = "foo bar"
        #expect {@evaluator.evaluate_conditions(@mailing.conditions)}.to raise_error(Liquid::Error)
        expect(MailyHerald::Utils::MarkupEvaluator.test_conditions(@mailing.conditions)).to be_falsy
        expect(@mailing).not_to be_valid
        expect(@mailing.errors).to include(:conditions)
      end

      it "should validate numerical conditions" do
        @mailing.conditions = "2"
        expect {@mailing.conditions_met?(@user)}.to raise_error

        @mailing.conditions = "5 == 5"
        @evaluator.evaluate_conditions(@mailing.conditions).should be_truthy
        expect {@mailing.conditions_met?(@user)}.not_to raise_error

        @mailing.conditions = "2 == 3"
        @evaluator.evaluate_conditions(@mailing.conditions).should be_falsy
        expect {@mailing.conditions_met?(@user)}.not_to raise_error
      end

      it "should evaluate more complex conditions" do
        expect(@user.weekly_notifications).to be_truthy

        @mailing.conditions = "user.weekly_notifications == true"
        @evaluator.evaluate_conditions(@mailing.conditions).should be_truthy
        expect {@mailing.conditions_met?(@user)}.not_to raise_error

        @mailing.conditions = "user.weekly_notifications == false"
        @evaluator.evaluate_conditions(@mailing.conditions).should be_falsy
        expect {@mailing.conditions_met?(@user)}.not_to raise_error

        @user.weekly_notifications = false
        expect(@user.weekly_notifications).to be_falsy

        @mailing.conditions = "user.weekly_notifications == true"
        @evaluator.evaluate_conditions(@mailing.conditions).should be_falsy
        expect {@mailing.conditions_met?(@user)}.not_to raise_error
      end

      it "should provide model conditions syntax validation" do
        @mailing.should be_valid
        @mailing.conditions = "foo bar"
        @mailing.should_not be_valid
      end
    end

    describe "start at" do
      it "should validate syntax" do
        expect(@mailing).to be_valid
        @mailing.start_at = "- foo bar | ddd"
        expect(MailyHerald::Utils::MarkupEvaluator.test_start_at(@mailing.start_at)).to be_falsy
        expect(@mailing).not_to be_valid
        expect(@mailing.errors).to include(:start_at)
      end

      it "should evaluate attributes" do
        expect(@evaluator.evaluate_start_at("user.created_at")).to eq(@user.created_at)
      end

      it "should evaluate attributes with filters" do
        expect(@evaluator.evaluate_start_at("user.created_at | minus: 1, 'day'")).to eq(@user.created_at - 1.day)

        expect(@evaluator.evaluate_start_at("user.created_at | plus: 2, 'minutes'")).to eq(@user.created_at + 2.minutes)
      end

      it "should evaluate attributes without subscription" do
        @evaluator = MailyHerald::Utils::MarkupEvaluator.new(@list.context.drop_for(@user, nil))
        expect(@evaluator.evaluate_start_at("user.created_at")).to eq(@user.created_at)
      end
    end
  end
end
