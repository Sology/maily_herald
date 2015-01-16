MailyHerald.setup do |config|
  config.token_redirect {|subscription| "/" }

  config.context :all_users do |context|
    context.scope {User.active}
    context.destination_attribute = :email
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
    list.token_custom_action do |controller, subscription|
      user = subscription.entity
      user.name = "changed"
      user.save!
      controller.redirect_to "/custom"
    end
  end

  config.one_time_mailing :test_mailing do |mailing|
    mailing.enable
    mailing.title = "Test mailing"
    mailing.subject = "Test mailing"
    mailing.list = :generic_list
    mailing.template = "User name: {{user.name}}."
  end

  config.one_time_mailing :sample_mail do |mailing|
    mailing.enable
    mailing.title = "Sample mailing"
    mailing.list = :generic_list
    mailing.mailer_name = "TestMailer"
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
    mailing.conditions = "user.weekly_notifications"
  end

  config.periodical_mailing :weekly_summary_sg do |mailing|
    mailing.enable
    mailing.title = "Weekly summary"
    mailing.subject = "Weekly summary"
    mailing.start_at = "user.created_at"
    mailing.list = :generic_list
    mailing.title = "Test periodical mailing"
    mailing.template = "User name: {{user.name}}."
    mailing.period = 7.days
    mailing.conditions = "user.weekly_notifications"
  end
end
