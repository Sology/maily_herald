require 'action_view/helpers/form_helper'

module MailyHerald
	module Webui
		class LabelledFormBuilder < ActionView::Helpers::FormBuilder
			(field_helpers.map(&:to_s) - %w(radio_button file_field check_box hidden_field fields_for) + %w(date_select)).each do |selector|
				src = <<-END_SRC
				def #{selector}(field, options = {})
					field = field.to_sym
					errors = @object.errors.to_hash
					errors = errors.merge(@object.all_translations_errors) if @object.respond_to?(:translated_attributes)
					comment = options.delete(:comment)

					@template.content_tag(:div, :class => "control-group \#{'error' if errors[field]}") do
						@template.concat(label_for_field(field, options))
						@template.concat(@template.content_tag(:div, :class => "controls") do
							if options[:addon]
								@template.concat(@template.content_tag(:div, :class => "input-append") do
									@template.concat(super(field, options.except(:label, :required)))
									@template.concat(@template.content_tag(:span, :class => "add-on") do
										@template.concat(@template.content_tag(:i, '', :class => "glyphicon glyphicon-" + options.delete(:addon)))
									end)
								end)
							else
								@template.concat(super(field, options.except(:label, :required)))
							end
							if comment
								@template.concat(@template.content_tag(:span, comment, :class => "form-comment"))
							end
							if options[:help]
								@template.concat(@template.link_to("#", :title => options.delete(:help), :"data-toggle" => "tooltip", :"data-html" => "true", :class => "form-help") do
									@template.concat(@template.content_tag(:i, '', :class => "glyphicon glyphicon-info-sign"))
								end) 
							end
							if errors[field]
								@template.concat(@template.content_tag(:span, errors[field].is_a?(Array) ? errors[field].first : errors[field], :class => "help-inline")) 
							end
						end)
					end
				end
				END_SRC
				class_eval src, __FILE__, __LINE__
			end

			def check_box(field, options = {}, checked_value = "1", unchecked_value = "0")
				errors = @object.errors.to_hash
				errors = errors.merge(@object.all_translations_errors) if @object.respond_to?(:translated_attributes)

				@template.content_tag(:div, :class => "control-group #{'error' if errors[field]}") do
					@template.concat(@template.content_tag(:div, :class => "controls") do
						@template.concat(label_for_field(field, options) do
							super(field, options.except(:label, :required), checked_value, unchecked_value)
						end)
						if options[:comment]
							@template.concat(@template.content_tag(:span, options.delete(:comment), :class => "form-comment"))
						end
						if options[:help]
							@template.concat(@template.link_to("#", :title => options.delete(:help), :"data-toggle" => "tooltip", :class => "form-help") do
								@template.concat(@template.content_tag(:i, '', :class => "glyphicon glyphicon-info-sign"))
							end) 
						end
						if errors[field]
							@template.concat(@template.content_tag(:span, errors[field].is_a?(Array) ? errors[field].first : errors[field], :class => "help-inline")) 
						end
					end)
				end
			end

			def check_box_plain(field, options = {}, checked_value = "1", unchecked_value = "0")
				errors = @object.errors.to_hash
				errors = errors.merge(@object.all_translations_errors) if @object.respond_to?(:translated_attributes)

				@template.content_tag(:p) do
					@template.concat(label_for_field(field, options) do
						@template.check_box(@object_name, field, options.except(:label, :required), checked_value, unchecked_value)
					end)
					if options[:comment]
						@template.concat(@template.content_tag(:span, options.delete(:comment), :class => "form-comment"))
					end
					if options[:help]
						@template.concat(@template.link_to("#", :title => options.delete(:help), :"data-toggle" => "tooltip", :class => "form-help") do
							@template.concat(@template.content_tag(:i, '', :class => "glyphicon glyphicon-info-sign"))
						end) 
					end
					if errors[field]
						@template.concat(@template.content_tag(:span, errors[field].is_a?(Array) ? errors[field].first : errors[field], :class => "help-inline")) 
					end
				end
			end

			def enum(method, options={})
				object_name = @object ? @object.class.name : @object_name.to_s

				list = "#{object_name.camelcase}::#{method.to_s.upcase}".constantize
				list = list.keys if list.is_a?(Hash)
				values = list.compact.map {|l| [ @template.t(l, :scope => [:activerecord, :enums, object_name.underscore, method]), l]}

				select(method, @template.options_for_select(values, @object.try(method)), {:prompt => @template.t(".#{method}.prompt")}.merge(options))
			end

			def datetime(field, options = {})
				field = field.to_sym
				errors = @object.errors.to_hash
				errors = errors.merge(@object.all_translations_errors) if @object.respond_to?(:translated_attributes)
				options[:class] ||= ""
				options[:class] = options[:class] + " inputmask"
				options[:data] ||= {}
				options[:data][:mask] = "9999-99-99 99:99"

				@template.content_tag(:div, :class => "control-group #{'error' if errors[field]}") do
					@template.concat(label_for_field(field, options))
					@template.concat(@template.content_tag(:div, :class => "controls") do
						@template.concat(@template.content_tag(:div, :class => "input-append date datepicker") do
							@template.concat(self.class.superclass.instance_method(:text_field).bind(self).call(field, options.except(:label, :required)))
							@template.concat(@template.content_tag(:span, :class => "add-on") do
								@template.concat(@template.content_tag(:i, '', :class => "glyphicon glyphicon-calendar"))
							end)
						end)
						if options[:comment]
							@template.concat(@template.content_tag(:span, options.delete(:comment), :class => "form-comment"))
						end
						if options[:help]
							@template.concat(@template.link_to("#", :title => options.delete(:help), :"data-toggle" => "tooltip", :class => "form-help") do
								@template.concat(@template.content_tag(:i, '', :class => "glyphicon glyphicon-info-sign"))
							end) 
						end
						if errors[field]
							@template.concat(@template.content_tag(:span, errors[field].is_a?(Array) ? errors[field].first : errors[field], :class => "help-inline")) 
						end
					end)
				end
			end

			def select(field, choices, options={})
				field = field.to_sym
				errors = @object.errors.to_hash
				errors = errors.merge(@object.all_translations_errors) if @object.respond_to?(:translated_attributes)

				@template.content_tag(:div, :class => "control-group #{'error' if errors[field]}") do
					@template.concat(label_for_field(field, options))
					@template.concat(@template.content_tag(:div, :class => "controls") do
						@template.concat(super(field, choices, options))
						if options[:comment]
							@template.concat(@template.content_tag(:span, options.delete(:comment), :class => "form-comment"))
						end
						if options[:help]
							@template.concat(@template.link_to("#", :title => options.delete(:help), :"data-toggle" => "tooltip", :class => "form-help") do
								@template.concat(@template.content_tag(:i, '', :class => "glyphicon glyphicon-info-sign"))
							end) 
						end
						if errors[field]
							@template.concat(@template.content_tag(:span, errors[field].is_a?(Array) ? errors[field].first : errors[field], :class => "help-inline")) 
						end
					end)
				end
			end

			# Returns a label tag for the given field
			def label_for_field(field, options = {})
				return ''.html_safe if options.delete(:no_label)
				text = ''
				text += yield if block_given?
				text += options[:label].is_a?(Symbol) ? l(options[:label]) : options[:label] if options[:label]
				text += @template.t(field.to_s, :scope => [:activerecord, :attributes, object_name.underscore]) unless options[:label]
				@template.content_tag(:label, text.html_safe,
															:class => (block_given? ? "checkbox " : "control-label ").to_s + (@object && @object.errors[field].present? ? "error" : nil).to_s,
															:for => (@object_name.to_s.gsub(/[\[\]]/,'_') + "_" + field.to_s).gsub(/__/, '_'))
			end

			def buttons_save_cancel
				@template.content_tag :div, :class => "control-group" do
					@template.concat(@template.content_tag(:div, :class => "controls") do
						@template.concat(@template.content_tag(:button, @template.t("form_commons.save"), :class => "btn btn-primary", :type => "submit"))
						@template.concat(' ')
						@template.concat(@template.content_tag(:button, @template.t("form_commons.cancel"), :class => "btn cancel"))
					end)
				end
			end

			def buttons *bs
				@template.content_tag :div, :class => "control-group" do
					@template.concat(@template.content_tag(:div, :class => "controls") do
						bs.each do |button|
							if button.is_a?(Symbol)
								case button
								when :submit
									@template.concat(@template.content_tag(:button, @template.t("form_commons.submit"), :class => "btn btn-primary", :type => "submit"))
								end
							end
						end
					end)
				end
			end
		end
	end
end
