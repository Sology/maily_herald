require 'spec_helper'

describe MailyHerald::Mailing do
  describe "Validations" do
    it {should validate_presence_of(:context_name)}
    it {should validate_presence_of(:name)}
    it {should validate_presence_of(:title)}
    it {should validate_presence_of(:template)}
  end

  describe "Associations" do
    it {should have_many(:records)}
    it {should belong_to(:sequence)}
  end
end
