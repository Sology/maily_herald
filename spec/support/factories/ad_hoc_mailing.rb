FactoryGirl.define do
  factory :ad_hoc_mailing, class: "MailyHerald::AdHocMailing" do
    type "MailyHerald::AdHocMailing"
    mailer_name "AdHocMailer"
    name "ad_hoc_mail"
    title "Ad hoc mailing"
    state "enabled"
    override_subscription false
  end
end
