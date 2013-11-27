require 'maily_herald/webui/labelled_form_builder'

module MailyHeraldHelper
   def sequence_mailing_list_actions mailing
     actions = [
      {
         :name => :custom,
         :url => webui_mailing_path(mailing),
         :icon => "glyphicon glyphicon-hand-right",
         :title => "Show"
       },
       {
         :name => :custom,
         :url => edit_webui_mailing_path(mailing),
         :icon => "glyphicon glyphicon-pencil",
         :title => "Edit"
       },
       { 
				 :name => :custom,
         :url => webui_mailing_path(mailing),
         :method => :delete,
         :confirm => "Are you sure you want to remove this mailing?",
         :icon => "glyphicon glyphicon-trash",
         :title => "Remove"
       }
    ]
     actions.insert(0, {
       :name => :custom,
      :url => "#mailing-#{mailing.id}",
       :class => "show-preview",
      :icon => "glyphicon glyphicon-search",
       :title => "Preview"
     }) if @sequence && @subscription
     actions
   end

  def sequence_entity_list_actions entity
		[
			{
				:name => :custom,
				:url => subscription_webui_sequence_path(:entity_id      => entity),
				:icon => "glyphicon glyphicon-hand-right",
				:title => "Show"
			}
		]
	end
	def mailing_entity_list_actions mailing, entity
		actions = []
		actions.push({
			:name => :custom,
			:url => preview_webui_mailing_path(:subscription_id => mailing.subscription_for(entity)),
			:icon => "glyphicon glyphicon-search",
			:title => "Preview template below",
			:remote => true
		})
		actions.push({
			:name => :custom,
			:url => mailing.sequence? ? subscription_webui_sequence_path(:id => mailing.sequence, :entity_id => entity) : subscription_webui_mailing_path(:entity_id => entity),
			:icon => "glyphicon glyphicon-hand-right",
			:title => "Show"
		})
		actions
	end
	
	def time_tag(time)
		return unless time
		text = distance_of_time_in_words(Time.now, time)
		content_tag('abbr', text, :title => format_time(time))
	end

	def time_tag_ago(time)
		return unless time
		text = distance_of_time_in_words(Time.now, time)
	  content_tag('abbr', t('time_distance.ago', :text => text), :title => time)
	 end
	
	def time_tag_to(time)
		return unless time
		text = distance_of_time_in_words(Time.now, time)
		content_tag('abbr', t('time_distance.in', :text => text), :title => time)
	end

	def delivery_log_list_actions delivery_log
		mailing = delivery_log.mailing
		entity = delivery_log.entity

		actions = []
		actions.push({
			:name => :custom,
			:url => webui_dashboard_path(delivery_log),
			:icon => "icon-search",
			:title => "Show log details"
		})
		actions.push({
			:name => :custom,
			:url => mailing.sequence? ? subscription_webui_sequence_path(:id => mailing.sequence, :entity_id => entity) : subscription_webui_mailing_path(:id => mailing, :entity_id => entity),
			:icon => "icon-hand-right",
			:title => "Subscription"
		}) unless @subscription
		actions
	end

	def subscription_group_subscription_actions subscription
		[{
			:name => :custom,
			:url => toggle_subscription_webui_subscription_group_path(:subscription_id => subscription),
			:method => :get,
			:confirm => "Are you sure you want to change this subscription?",
			:icon => "icon-refresh",
			:title => "Toggle subscription"
		}]
	end

	def time_tag_relative(time)
		if time > Time.now
			 time_tag_to time
		else
			 time_tag_ago time
		end
	end

	def display_context_attributes attributes
		content_tag(:ul) do
			attributes.each do |k, v|
				if v.is_a?(Hash)
					concat(content_tag(:li) do
						concat(k)
						concat(display_context_attributes(v))
					end)
				else
					concat(content_tag(:li, k))
				end
			end
		end
	end
 
	def context_attributes_link options = {}
		link_to context_attributes_webui_mailings_path(:context_name => options[:context]), :role => "button", :data => {:toggle => "modal", :target => "#context-attributes"}, :class => "show-context-attributes" do
       concat(content_tag(:i, "", :class => "glyphicon glyphicon-th-list"))
       concat(" show") unless options[:notext]
		end
	end

	def labelled_form_for(*args, &proc)
		args << {} unless args.last.is_a?(Hash)
		options = args.last
		if args.first.is_a?(Symbol)
			options.merge!(:as => args.shift)
		end
		html = {:class => "form-horizontal #{'wide' if options.delete(:wide)} #{options.delete(:class)}"}
		html[:data] ||= {}
		html[:data][:observe] = true if options.delete(:observe)
		options.merge!({:builder => MailyHerald::Webui::LabelledFormBuilder, :html => html})
		form_for(*args, &proc)
	end

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
