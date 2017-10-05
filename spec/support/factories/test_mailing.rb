FactoryGirl.define do
  factory :test_mailing, class: "MailyHerald::OneTimeMailing" do
    type "MailyHerald::OneTimeMailing"
    conditions "user.weekly_notifications == true"
    start_at "user.created_at"
    mailer_name "generic"
    name "test_mailing"
    title "Test mailing"
    subject "Test mailing"
    template "User name: {{user.name}}."
    list :generic_list
    state "enabled"
    override_subscription false
  end
end
