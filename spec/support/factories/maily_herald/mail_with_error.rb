FactoryGirl.define do
  factory :mail_with_error, class: "MailyHerald::OneTimeMailing" do
    type "MailyHerald::OneTimeMailing"
    start_at "user.created_at"
    mailer_name "CustomOneTimeMailer"
    name "mail_with_error"
    from nil
    template nil
    subject nil
    title "Mail with error"
    list :generic_list
    state "enabled"
  end
end
