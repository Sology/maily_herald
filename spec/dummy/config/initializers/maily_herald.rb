MailyHerald.setup do |config|
  config.default_from = 'no-reply@maily_herald.com'

  config.context :all_users do |context|
    context.scope {User.scoped}
    context.destination {|user| user.email}
    context.attribute(:user) do |user|
      {
        'name' => user.name,
        'email' => user.email,
        'weekly_notifications' => user.weekly_notifications,
        'created_at' => user.created_at,
      }
    end
  end

  config.one_time_mailing :test_mailing do |mailing|
    mailing.title = "Test mailing"
    mailing.context_name = :all_users
    mailing.template = "User name: {{user.name}}."
    mailing.enabled = true
  end

  config.sequence :newsletters do |seq|
    seq.context_name = :all_users
    seq.start_var = "user.created_at"
    seq.enabled = true
    seq.mailing :initial_mail do |mailing|
      mailing.title = "Test mailing #1"
      mailing.template = "User name: {{user.name}}."
      mailing.relative_delay = 1.hour
      mailing.enabled = true
    end
    seq.mailing :second_mail do |mailing|
      mailing.title = "Test mailing #2"
      mailing.template = "User name: {{user.name}}."
      mailing.relative_delay = 2.hours
      mailing.enabled = true
    end
  end

  config.periodical_mailing :weekly_summary do |mailing|
    mailing.start_var = "user.created_at"
    mailing.context_name = :all_users
    mailing.title = "Test periodical mailing"
    mailing.template = "User name: {{user.name}}."
    mailing.period = 7.days
    mailing.conditions = "user.weekly_notifications"
    mailing.enabled = true
  end
end
