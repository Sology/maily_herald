module MailyHerald

  # Abstraction layer for accessing collections of Entities and their attributes.
  # Information provided by scope is used while sending {MailyHerald::Mailing mailings}.
  #
  # {Context} defines following:
  #
  # * Entity scope - +ActiveRecord::Relation+, list of Entities that will be returned 
  #   by {Context}.
  # * Entity model name - deducted automatically from scope.
  # * Entity attributes - Defined as procs that can be evaluated for every item of 
  #   the scope (single Entity).
  #
  # * Entity email - defined as proc or string/symbol (email method name).
  #
  class Context

    # Context Attributes drop definition for Liquid
    class Drop < Liquid::Drop
      def initialize attrs
        @attrs = attrs
      end

      def has_key?(name)
        name = name.to_s

        @attrs.has_key? name
      end

      def invoke_drop name
        name = name.to_s

        if @attrs.has_key? name
          if @attrs[name].is_a? Hash
            Drop.new(@attrs[name])
          else
            @attrs[name].call
          end
        else
          nil
        end
      end

      alias :[] :invoke_drop
    end

    class Attributes
      def initialize block
        @attrs = {}
        @node = @parent_node = @attrs
        @block = block
      end

      def setup entity = nil, subscription = nil, log = nil
        if entity
          @attrs["subscription"] = Proc.new{ subscription } if subscription
          @attrs["log"] = Proc.new{ log } if log
          instance_exec entity, &@block
        else
          instance_eval &@block
        end
      end

      def attribute_group name, &block
        @parent_node = @node
        @parent_node[name.to_s] ||= {}
        @node = @parent_node[name.to_s]
        yield
        @node = @parent_node
      end

      def attribute name, &block
        @node[name.to_s] = block
      end

      def for_drop
        @attrs
      end

      def method_missing(m, *args, &block)
        true
      end
    end

    class JoinedScope
      attr_reader :scope, :options, :model

      delegate :all, to: :scope

      def initialize scope, options = {}
        @model = scope.klass
        @scope = scope.select("#{model.table_name}.*")
        @options = options
      end

      def list
        @list ||= options[:list] || MailyHerald::List.find_by(id: options[:list_id]) || mailing.try(:list) || mailing.try(:first).try(:list)
      end

      def list_id
        @list_id ||= options[:list_id] || list.try(:id)
      end

      def mailing
        @mailing ||= options[:mailing] || MailyHerald::Mailing.find_by(id: options[:mailing_id])
      end

      def mailing_id
        @mailing_id ||= options[:mailing_id] || mailing.try(:id) || mailing.try(:ids).try(:join, ',')
      end

      def join_mode_str
        @join_mode_str ||= case options[:join_mode]
                           when :outer
                             "LEFT OUTER JOIN"
                           else
                             "INNER JOIN"
                           end
      end

      def subscription_fields_select
        @subscription_fields_select ||= MailyHerald::Subscription.columns.collect{|c| "#{MailyHerald::Subscription.table_name}.#{c.name} AS maily_subscription_#{c.name}"}.join(", ")
      end

      def with_subscriptions options = {}
        @scope = @scope.select(subscription_fields_select).joins(
          "#{join_mode_str} #{MailyHerald::Subscription.table_name} ON #{MailyHerald::Subscription.table_name}.entity_id = #{model.table_name}.id AND #{MailyHerald::Subscription.table_name}.entity_type = '#{model.base_class.to_s}' AND #{MailyHerald::Subscription.table_name}.list_id = '#{list_id}'"
        )
        @scope = @scope.where("#{MailyHerald::Subscription.table_name}.active" => options[:subscription_active]) if options[:subscription_active]
        self
      end

      def log_fields_select
        @log_fields_select ||= MailyHerald::Log.columns.collect{|c| "#{MailyHerald::Log.table_name}.#{c.name} AS maily_log_#{c.name}"}.join(", ")
      end

      def with_logs options = {}
        @scope = @scope.select(log_fields_select).joins(
          "#{join_mode_str} #{MailyHerald::Log.table_name} ON #{MailyHerald::Log.table_name}.mailing_id IN (#{mailing_id}) AND #{MailyHerald::Log.table_name}.entity_id = #{model.table_name}.id AND #{MailyHerald::Log.table_name}.entity_type = '#{model.base_class.to_s}'"
        )
        @scope = @scope.where("#{MailyHerald::Log.table_name}.status" => options[:log_status]) if options[:log_status]
        self
      end
    end

    # Friendly name of the {Context}.
    #
    # Displayed ie. in the Web UI.
    attr_accessor :title

    # Identification name of the {Context}. 
    #
    # This can be then used in {MailyHerald.context} method to fetch the {Context}.
    #
    # @see MailyHerald.context
    attr_reader :name

    attr_writer :destination

    # Creates {Context} and sets its name.
    def initialize name
      @name = name
    end

    # Defines or returns Entity scope - collection of Entities.
    #
    # If block passed, it is saved as scope proc. Block has to return 
    # +ActiveRecord::Relation+ containing entity objects that will belong to scope.
    #
    # If no block given, scope proc is called and entity collection returned.
    def scope &block
      if block_given?
        @scope = block
      else
        @scope.call
      end
    end

    def joined_scope options = {}
      JoinedScope.new(scope, options)
    end

    # Fetches the Entity model class based on scope.
    def model
      @model ||= @scope.call.klass
    end

    # Entity email address.
    #
    # Can be eitner +Proc+ or attribute name (string, symbol).
    #
    # If block passed, it is saved as destination proc. Block has to:  
    #
    # * accept single Entity object, 
    # * return Entity email. 
    #
    # If no block given, +destination+ attribute is returned (a string, symbol or proc).
    def destination &block
      if block_given?
        @destination = block
      else
        @destination
      end
    end

    # Returns Entity email attribute name only if it is not defined as a proc.
    def destination_attribute
      @destination unless @destination.respond_to?(:call)
    end

    # Fetches Entity's email address based on {Context} destination definition.
    def destination_for entity
      destination_attribute ? entity.send(@destination) : @destination.call(entity)
    end

    # Simply filter Entity scope by email.
    #
    # If destination is provided in form of Entity attribute name (not the proc), 
    # this method creates the scope filtered by `query` email using SQL LIKE.
    #
    # @param query [String] email address which is being searched.
    # @return [ActiveRecord::Relation] collection filtered by email address
    def scope_like query
      if destination_attribute
        scope.where("#{model.table_name}.#{destination_attribute} LIKE (?)", "%#{query}%")
      end
    end

    # Returns Entity collection scope with joined {MailyHerald::Subscription}.
    #
    # @param list [List, Fixnum, String] {MailyHerald::List} reference
    # @param mode [:inner, :outer] SQL JOIN mode
    def scope_with_subscription list, mode = :inner
      joined_scope(join_mode: mode, list: list).with_subscriptions.all
    end

    # Returns Entity collection scope with joined {MailyHerald::Log} for given mailing.
    #
    # @param mailing [Mailing, Fixnum, String] {MailyHerald::Mailing} reference
    # @param mode [:inner, :outer] SQL JOIN mode
    def scope_with_log mailing, mode = :inner, options = {}
      joined_scope(join_mode: mode, mailing: mailing).with_subscriptions(options).with_logs(options).all
    end

    # Sepcify or return {Context} attributes.
    #
    # Defines Entity attributes that can be accessed using this Context.
    # Attributes defined this way are then accesible in Liquid templates 
    # in Generic Mailer ({MailyHerald::Mailer#generic}).
    #
    # If block passed, it is used to create Context Attributes.  
    #
    # If no block given, current attributes are returned.
    def attributes &block
      if block_given?
        @attributes = Attributes.new block
      else
        @attributes
      end
    end

    # Obtains {Context} attributes in a form of (nested) +Hash+ which 
    # values are procs each returning single Entity attribute value.
    def attributes_list
      return {} unless @attributes

      attributes = @attributes.dup
      attributes.setup 
      attributes.for_drop
    end

    # Returns Liquid drop created from Context attributes.
    def drop_for entity, subscription, log = nil
      return {} unless @attributes

      attributes = @attributes.dup
      attributes.setup entity, subscription, log
      Drop.new(attributes.for_drop)
    end
  end
end
