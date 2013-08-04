module MailyHeraldHelper
  def maily_herald_context_options_for_select selected = nil, options = {}
    MailyHerald.contexts.keys.collect {|c| [c, c] }
  end

  def maily_herald_sequence_mode_options_for_select selected = nil, options = {}
    [:chronological, :periodical].collect {|c| [c, c] }
  end

  def maily_herald_mailer_options_for_select selected = nil, options = {}
    [
      ['generic', 'generic']
    ]
  end

  def maily_herald_context_attributes_list name
    MailyHerald.context(name).each
  end
end
