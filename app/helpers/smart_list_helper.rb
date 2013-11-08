module SmartListHelper
  module ControllerExtensions
    def smart_list_create name, collection, options = {}
      name = name.to_sym

      list = SmartList.new(name, collection, options)
      list.setup(params, cookies)

      @smart_lists ||= {}
      @smart_lists[name] = list

      list.collection
    end

    def smart_list name
      @smart_lists[name.to_sym]
    end
  end

  class SmartListBuilder
    # Params that should not be visible in pagination links (pages, per-page, sorting, etc.)
    UNSAFE_PARAMS = {:authenticity_token => nil, :utf8 => nil}

    class_attribute :smart_list_helpers
    self.smart_list_helpers = (SmartListHelper.instance_method_names - ['smart_list_for'])

    def initialize(smart_list_name, smart_list, template, options, proc)
      @smart_list_name, @smart_list, @template, @options, @proc = smart_list_name, smart_list, template, options, proc
    end

    def paginate options = {}
      if @smart_list.collection.respond_to? :current_page
        @template.paginate @smart_list.collection, :remote => true, :param_name => @smart_list.param_names[:page], :params => UNSAFE_PARAMS
      end
    end

    def collection
      @smart_list.collection
    end

    def pagination_per_page_links options = {}
      @template.content_tag(:div, :class => "pagination_per_page #{'disabled' if empty?}") do
        if @smart_list.count > SmartList::PAGE_SIZES.first
          @template.concat(@template.t('views.pagination.per_page'))
          per_page_sizes = SmartList::PAGE_SIZES.clone
          per_page_sizes.push(0) if @smart_list.unlimited_per_page?
          per_page_sizes.each do |p|
            name = p == 0 ? @template.t('views.pagination.unlimited') : p
            if @smart_list.per_page.to_i != p
              @template.concat(@template.link_to(name, sanitize_params(@template.params.merge(@smart_list.param_names[:per_page] => p, @smart_list.param_names[:page] => 1)), :remote => true))
            else 
              @template.concat(@template.content_tag(:span, name))
            end
            break if p > @smart_list.count
          end
          @template.concat ' | '
        end if @smart_list.options[:paginate]
        @template.concat(@template.t('views.pagination.total'))
        @template.concat(@template.content_tag(:span, @smart_list.count, :class => "count"))
      end
    end

    def sortable title, attribute, options = {}
      extra = options.delete(:extra)

      sort_params = {
        @smart_list.param_names[:sort_attr] => attribute, 
        @smart_list.param_names[:sort_order] => (@smart_list.sort_order == "asc") ? "desc" : "asc", 
        @smart_list.param_names[:sort_extra] => extra
      }

      @template.link_to(sanitize_params(@template.params.merge(sort_params)), :class => "sortable", :data => {:attr => attribute}, :remote => true) do
        @template.concat(title)
        if @smart_list.sort_attr == attribute && (!@smart_list.sort_extra || @smart_list.sort_extra == extra.to_s)
          @template.concat(@template.content_tag(:span, "", :class => (@smart_list.sort_order == "asc" ? "icon-chevron-up" : "icon-chevron-down"))) 
        else
          @template.concat(@template.content_tag(:span, "", :class => "icon-resize-vertical"))
        end
      end
    end

    def update options = {}
      part = options.delete(:partial) || @smart_list.partial || @smart_list_name

      @template.render(:partial => 'smart_list/update_list', :locals => {:name => @smart_list_name, :part => part, :smart_list => self})
    end

    # Renders the main partial (whole list)
    def render_list
      if @smart_list.partial
        @template.render :partial => @smart_list.partial, :locals => {:smart_list => self}
      end
    end

    # Basic render block wrapper that adds smart_list reference to local variables
    def render options = {}, locals = {}, &block
      if locals.empty?
        options[:locals] ||= {}
        options[:locals].merge!(:smart_list => self)
      else
        locals.merge!({:smart_list => self})
      end
      @template.render options, locals, &block
    end

    # Add new item button & placeholder to list
    def item_new options = {}
      @template.concat(@template.content_tag(:tr, '', :class => "info new_item_placeholder disabled"))
      @template.concat(@template.content_tag(:tr, :class => "info new_item_action #{'disabled' if !empty? && max_count?}") do
        @template.concat(@template.content_tag(:td, :colspan => options.delete(:colspan)) do
          @template.concat(@template.content_tag(:p, :class => "no_records pull-left #{'disabled' unless empty?}") do
            @template.concat(options.delete(:no_items_text))
          end)
          @template.concat(@template.link_to(options.delete(:link), :remote => true, :class => "btn pull-right #{'disabled' if max_count?}") do
            @template.concat(@template.content_tag(:i, '', :class => "icon-plus"))
            @template.concat(" ")
            @template.concat(options.delete(:text))
          end)
        end)
      end)
      nil
    end

    # Check if smart list is empty
    def empty?
      @smart_list.count == 0
    end

    # Check if smart list reached its item max count
    def max_count?
      return false if @smart_list.max_count.nil?
      @smart_list.count >= @smart_list.max_count
    end

    private

    def sanitize_params params
      params.merge(UNSAFE_PARAMS)
    end
  end

  # Outputs smart list container
  def smart_list_for name, *args, &block
    raise ArgumentError, "Missing block" unless block_given?
    name = name.to_sym
    options = args.extract_options!
    bare = options.delete(:bare)

    builder = SmartListBuilder.new(name, @smart_lists[name], self, options, block)

    output =""

    data = {}
    data['max-count'] = @smart_lists[name].max_count if @smart_lists[name].max_count && @smart_lists[name].max_count > 0
    data['href'] = @smart_lists[name].href if @smart_lists[name].href

    if bare
      output = capture(builder, &block)
    else
      output = content_tag(:div, :class => "smart_list", :id => name, :data => data) do
        concat(content_tag(:div, "", :class => "loading"))
        concat(content_tag(:div, :class => "content") do
          concat(capture(builder, &block))
        end)
      end
    end

    output
  end

  # Render item action buttons (ie. edit, destroy and custom ones)
  def smart_list_item_actions actions = []
    content_tag(:span) do
      actions.each do |action|
        next unless action.is_a?(Hash)

        if action.has_key?(:if)
          unless action[:if]
            concat(content_tag(:i, '', :class => "icon-remove-circle"))
            next
          end
        end

        case action.delete(:name).to_sym
        when :edit
          url = action.delete(:url)
          html_options = {
            :remote => true, 
            :class => "edit",
            :title => t("smart_list.actions.edit")
          }.merge(action)

          concat(link_to(url, html_options) do
            concat(content_tag(:i, '', :class => "icon-pencil"))
          end)
        when :destroy
          url = action.delete(:url)
          icon = action.delete(:icon) || "icon-trash"
          html_options = {
            :remote => true, 
            :class => "destroy",
            :method => :delete,
            :title => t("smart_list.actions.destroy"),
            :data => {:confirmation => action.delete(:confirmation) || t("smart_list.msgs.destroy_confirmation")},
          }.merge(action)

          concat(link_to(url, html_options) do
            concat(content_tag(:i, '', :class => icon))
          end)
        when :custom
          url = action.delete(:url)
          icon = action.delete(:icon)
          html_options = action

          concat(link_to(url, html_options) do
            concat(content_tag(:i, '', :class => icon))
          end)
        end
      end
    end
  end

  def smart_list_limit_left name
    name = name.to_sym
    smart_list = @smart_lists[name]

    smart_list.max_count - smart_list.count
  end

  #################################################################################################
  # JS helpers:

  # Updates the smart list
  def smart_list_update name
    name = name.to_sym
    smart_list = @smart_lists[name]

    builder = SmartListBuilder.new(name, smart_list, self, {}, nil)

    render(:partial => 'smart_list/update_list', :locals => {
      :name => smart_list.name, 
      :part => smart_list.partial, 
      :smart_list => builder, 
      :smart_list_data => {
        :params => smart_list.all_params,
        'max-count' => smart_list.max_count,
      }
    })
  end

  # Renders single item (i.e for create, update actions)
  def smart_list_item name, item_action, object = nil, partial = nil, options = {}
    name = name.to_sym
    type = object.class.name.downcase.to_sym if object
    id = object.id if object
    object_key = options.delete(:object_key) || :object

    render(:partial => "smart_list/item/#{item_action.to_s}", :locals => {:name => name, :id => id, :object_key => object_key, :object => object, :part => partial})
  end
end
