MailyHerald.setup do |config|
  config.default_from = 'no-reply@maily_herald.com'

  config.context :all_users do |context|
    context.scope {User.scoped}
    context.destination {|user| user.email}
    context.attribute(:user) do |user|
      {
        'name' => user.name,
        'email' => user.email,
        'created_at' => user.created_at,
      }
    end
  end

  config.mailing :test_mailing do |mailing|
    mailing.title = "Test mailing"
    mailing.context_name = :all_users
    mailing.template = "User name: {{user.name}}."
  end

  config.sequence :newsletters do |seq|
    seq.context_name = :all_users
    seq.mode = "chronological"
    seq.start_var = "user.created_at"
    seq.mailing :initial_mail do |mailing|
      mailing.title = "Test mailing #1"
      mailing.template = "User name: {{user.name}}."
      mailing.delay_time = 1.hour
    end
    seq.mailing :second_mail do |mailing|
      mailing.title = "Test mailing #2"
      mailing.template = "User name: {{user.name}}."
      mailing.delay_time = 2.hours
    end
  end

  config.sequence :statistics do |seq|
    seq.context_name = :all_users
    seq.mode = "periodical"
    seq.start_var = "user.created_at"
    seq.period = 7.days
    seq.mailing :weekly_summary do |mailing|
      mailing.title = "Test periodical mailing"
      mailing.template = "User name: {{user.name}}."
    end
  end
end
