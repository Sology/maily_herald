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

    it "should validate syntax" do
      @mailing.conditions = "foo bar"
      expect {@evaluator.evaluate_conditions(@mailing.conditions)}.to raise_error(Liquid::Error)
      expect {MailyHerald::Utils::MarkupEvaluator.test_conditions(@mailing.conditions)}.to raise_error(Liquid::Error)
    end

    pending "should validate numerical conditions" do
      @mailing.conditions = "(2 * 3) - 1"
      @evaluator.evaluate_conditions(@mailing.conditions).should be_falsy
      expect {@mailing.test_conditions}.not_to raise_error(Liquid::Error)

      @mailing.conditions = "2 == 3"
      @evaluator.evaluate_conditions(@mailing.conditions).should be_falsy
      expect {@mailing.test_conditions}.not_to raise_error(Liquid::Error)

      @mailing.conditions = "1 * 2 + 3"
      @evaluator.evaluate_conditions(@mailing.conditions).should be_truthy
      expect {@mailing.test_conditions}.not_to raise_error(Liquid::Error)
    end

    it "should provide model conditions syntax validation" do
      @mailing.conditions = "foo bar"
      expect(@mailing).not_to be_valid
    end

    it "should evaluate attributes" do
      expect(@evaluator.evaluate_variable("user.created_at")).to eq(@user.created_at)
    end

    it "should evaluate attributes without subscription" do
      @evaluator = MailyHerald::Utils::MarkupEvaluator.new(@list.context.drop_for(@user, nil))
      expect(@evaluator.evaluate_variable("user.created_at")).to eq(@user.created_at)
    end
  end
end
