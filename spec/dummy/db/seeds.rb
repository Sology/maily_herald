MailyHerald.one_time_mailing :test_mailing do |mailing|
  mailing.enable
  mailing.title = "Test mailing"
  mailing.subject = "Test mailing"
  mailing.list = :generic_list
  mailing.start_at = "user.created_at"
  mailing.template = "User name: {{user.name}}."
end

MailyHerald.one_time_mailing :one_time_mail do |mailing|
  mailing.enable
  mailing.title = "One time mailing"
  mailing.list = :generic_list
  mailing.mailer_name = "CustomOneTimeMailer"
  mailing.start_at = "user.created_at"
end

MailyHerald.one_time_mailing :mail_with_error do |mailing|
  mailing.enable
  mailing.title = "Mail with error"
  mailing.list = :generic_list
  mailing.mailer_name = "CustomOneTimeMailer"
  mailing.start_at = "user.created_at"
end

MailyHerald.ad_hoc_mailing :ad_hoc_mail do |mailing|
  mailing.enable
  mailing.title = "Ad hoc mailing"
  mailing.list = :generic_list
  mailing.mailer_name = "AdHocMailer"
end

MailyHerald.sequence :newsletters do |seq|
  seq.enable
  seq.title = "Newsletters"
  seq.list = :generic_list
  seq.start_at = "user.created_at"
  seq.mailing :initial_mail do |mailing|
    mailing.title = "Test mailing #1"
    mailing.subject = "Test mailing #1"
    mailing.template = "User name: {{user.name}}."
    mailing.absolute_delay = 1.hour
    mailing.enable
  end
  seq.mailing :second_mail do |mailing|
    mailing.title = "Test mailing #2"
    mailing.subject = "Test mailing #2"
    mailing.template = "User name: {{user.name}}."
    mailing.absolute_delay = 3.hours
    mailing.enable
  end
  seq.mailing :third_mail do |mailing|
    mailing.title = "Test mailing #3"
    mailing.subject = "Test mailing #3"
    mailing.template = "User name: {{user.name}}."
    mailing.absolute_delay = 6.hours
    mailing.enable
  end
end

MailyHerald.periodical_mailing :weekly_summary do |mailing|
  mailing.enable
  mailing.title = "Weekly summary"
  mailing.subject = "Weekly summary"
  mailing.start_at = "user.created_at"
  mailing.list = :generic_list
  mailing.title = "Test periodical mailing"
  mailing.template = "User name: {{user.name}}."
  mailing.period = 7.days
  mailing.conditions = "user.weekly_notifications == true"
end
