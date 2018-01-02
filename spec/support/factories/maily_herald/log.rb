FactoryGirl.define do
  factory :log, class: "MailyHerald::Log" do
    association :mailing, factory: :ad_hoc_mailing
    status :scheduled
    processing_at { Time.now }
  end
end
