FactoryGirl.define do
  factory :initial_mail, class: "MailyHerald::SequenceMailing" do
    type "MailyHerald::SequenceMailing"
    mailer_name "generic"
    name "initial_mail"
    title "Test mailing #1"
    subject "Test mailing #1"
    template_plain "User name: {{user.name}}."
    absolute_delay 1.hour
    state "enabled"
  end

  factory :second_mail, class: "MailyHerald::SequenceMailing" do
    type "MailyHerald::SequenceMailing"
    mailer_name "generic"
    name "second_mail"
    title "Test mailing #2"
    subject "Test mailing #2"
    template_plain "User name: {{user.name}}."
    absolute_delay 3.hour
    state "enabled"
  end

  factory :third_mail, class: "MailyHerald::SequenceMailing" do
    type "MailyHerald::SequenceMailing"
    mailer_name "generic"
    name "third_mail"
    title "Test mailing #3"
    subject "Test mailing #3"
    template_plain "User name: {{user.name}}."
    absolute_delay 6.hour
    state "enabled"
  end
end
