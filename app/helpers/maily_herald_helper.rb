module MailyHeraldHelper
  def maily_herald_context_options_for_select selected = nil, options = {}
    MailyHerald.contexts.keys.collect {|c| [c, c] }
  end

  def maily_herald_mailer_options_for_select selected = nil, options = {}
    [
      ['generic', 'generic']
    ]
  end

  def maily_herald_context_attributes_list name
    MailyHerald.context(name).each
  end

  def maily_herald_token_action_options_for_select selected = nil, options = {}
    [
      ['Unsubscribe', 'unsubscribe'],
      ['Custom', 'custom'],
    ]
  end

  def maily_herald_subscription_group_options_for_select selected = nil, options = {}
    [["none", ""]] + MailyHerald::SubscriptionGroup.all.collect {|sg| [sg.title, sg.name] }
  end
end
