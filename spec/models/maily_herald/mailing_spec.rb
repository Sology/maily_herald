require 'spec_helper'

describe MailyHerald::Mailing do
  describe "Validations" do
    it {should validate_presence_of(:name)}
    it {should validate_presence_of(:title)}
    it {should validate_presence_of(:template)}
  end

  describe "Associations" do
    it {should have_many(:subscriptions)}
  end
end
