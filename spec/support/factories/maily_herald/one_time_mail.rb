FactoryGirl.define do
  factory :custom_one_time_mailing, class: "MailyHerald::OneTimeMailing" do
    type                    "MailyHerald::OneTimeMailing"
    start_at                "user.created_at"
    mailer_name             "CustomOneTimeMailer"
    name                    "one_time_mail"
    title                   "One time mailing"
    list                    :generic_list
    state                   "enabled"
  end

  factory :generic_one_time_mailing, class: "MailyHerald::OneTimeMailing" do
    type                    "MailyHerald::OneTimeMailing"
    conditions              "user.weekly_notifications == true"
    start_at                "user.created_at"
    mailer_name             "generic"
    name                    "test_mailing"
    title                   "Test mailing"
    subject                 "Test mailing"
    template_plain                "User name: {{user.name}}."
    list                    :generic_list
    state                   "enabled"
    from                    "foo@bar.com"
  end
end
