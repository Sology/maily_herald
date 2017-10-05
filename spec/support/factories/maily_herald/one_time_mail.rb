FactoryGirl.define do
  factory :one_time_mail, class: "MailyHerald::OneTimeMailing" do
    type "MailyHerald::OneTimeMailing"
    start_at "user.created_at"
    mailer_name "CustomOneTimeMailer"
    name "one_time_mail"
    title "One time mailing"
    list :generic_list
    state "enabled"
    override_subscription false
  end
end
