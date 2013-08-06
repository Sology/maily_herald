module MailyHerald
  class Context
    class Drop < Liquid::Drop
      def initialize attributes, entity, subscription
        @attributes = attributes
        @entity = entity
        @subscription = subscription
      end

      def has_key?(name)
        name = name.to_sym

        @attributes.has_key? name
      end

      def invoke_drop name
        name = name.to_sym

        if @attributes.has_key? name
          #@attributes[name].try(:call, @entity)
          @attributes[name].call(@entity)
        elsif name == :subscription
          @subscription
        else
          nil
        end
      end

      alias :[] :invoke_drop
    end

    attr_accessor :entity
    attr_reader :name

    def initialize name
      @name = name
      @attributes = {}
    end

    def model
      @model ||= @scope.call.table.engine
    end

    def scope &block
      if block_given?
        @scope = block
      else
        @scope.call
      end
    end

    def destination &block
      if block_given?
        @destination = block
      else
        @destination
      end
    end

    def attribute name, &block
      name = name.to_sym

      @attributes ||= {}
      if block_given?
        @attributes[name] = block
      else
        @attributes[name]
      end
    end

    def attribute_names
      @attributes.keys
    end

    #def each &block
      #@scope.call.each do |entity|
        #drop = Drop.new(@attributes, entity)
        #block.call(entity, drop)
      #end
    #end

    def drop_for entity, subscription
      Drop.new(@attributes, entity, subscription)
    end

  end
end
