module MailyHerald
  class Context
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

      def setup entity = nil, subscription = nil
        if entity
          @attrs["subscription"] = Proc.new{ subscription } if subscription
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

    attr_accessor :destination_attribute, :title
    attr_reader :name

    def initialize name
      @name = name
    end

    def model
      @model ||= @scope.call.klass
    end

    def scope &block
      if block_given?
        @scope = block
      else
        @scope.call
      end
    end

    def scope_like q
      if destination_attribute
        scope.where("#{model.table_name}.#{destination_attribute} LIKE (?)", "%#{q}%")
      end
    end

    def scope_with_subscription list, mode = :inner
      list_id = case list
                when List
                  list.id
                when Fixnum
                  list
                when String
                  list.to_i
                else
                  raise ArgumentError
                end

      join_mode = case mode
                  when :outer
                    "LEFT OUTER JOIN"
                  else
                    "INNER JOIN"
                  end

      subscription_fields_select = Subscription.columns.collect{|c| "#{Subscription.table_name}.#{c.name} AS maily_subscription_#{c.name}"}.join(", ")

      scope.select("#{model.table_name}.*, #{subscription_fields_select}").joins(
        "#{join_mode} #{Subscription.table_name} ON #{Subscription.table_name}.entity_id = #{model.table_name}.id AND #{Subscription.table_name}.entity_type = '#{model.base_class.to_s}' AND #{Subscription.table_name}.list_id = '#{list_id}'"
      )
    end

    def destination &block
      if block_given?
        @destination = block
      else
        @destination
      end
    end

    def destination_for entity
      @destination_attribute ? entity.send(@destination_attribute) : @destination.call(entity)
    end

    def attributes &block
      if block_given?
        @attributes = Attributes.new block
      else
        @attributes
      end
    end

    def attributes_list
      attributes = @attributes.dup
      attributes.setup 
      attributes.for_drop
    end

    def drop_for entity, subscription
      attributes = @attributes.dup
      attributes.setup entity, subscription
      Drop.new(attributes.for_drop)
    end

  end
end
