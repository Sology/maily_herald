MailyHerald.setup do |config|
  config.token_redirect {|subscription| "/" }

  config.context :all_users do |context|
    context.scope {User.active}
    context.destination {|user| user.email}
    context.attributes do |user| 
      attribute_group(:user) do
        attribute(:name) {user.name}
        attribute(:email) {user.email}
        attribute(:created_at) {user.created_at}
        attribute(:weekly_notifications) {user.weekly_notifications}
        attribute_group(:properties) do
          attribute(:prop1) { user.name[0] }
          attribute(:prop2) { 2 }
        end
      end
    end
  end

  config.list :generic_list do |list|
    list.context_name = :all_users
  end

  config.list :locked_list, locked: true do |list|
    list.context_name = :all_users
  end

  config.one_time_mailing :locked_mailing, locked: true do |mailing|
    mailing.enable
    mailing.title = "Test mailing"
    mailing.subject = "Test mailing"
    mailing.list = :generic_list
    mailing.start_at = "user.created_at"
    mailing.template = "User name: {{user.name}}."
  end

  config.one_time_mailing :test_mailing do |mailing|
    mailing.enable
    mailing.title = "Test mailing"
    mailing.subject = "Test mailing"
    mailing.list = :generic_list
    mailing.start_at = "user.created_at"
    mailing.template = "User name: {{user.name}}."
  end

  config.one_time_mailing :one_time_mail do |mailing|
    mailing.enable
    mailing.title = "One time mailing"
    mailing.list = :generic_list
    mailing.mailer_name = "CustomOneTimeMailer"
    mailing.start_at = "user.created_at"
  end

  config.one_time_mailing :mail_with_error do |mailing|
    mailing.enable
    mailing.title = "Mail with error"
    mailing.list = :generic_list
    mailing.mailer_name = "CustomOneTimeMailer"
    mailing.start_at = "user.created_at"
  end

  config.ad_hoc_mailing :ad_hoc_mail do |mailing|
    mailing.enable
    mailing.title = "Ad hoc mailing"
    mailing.list = :generic_list
    mailing.mailer_name = "AdHocMailer"
  end

  config.sequence :newsletters do |seq|
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

  config.periodical_mailing :weekly_summary do |mailing|
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
end
