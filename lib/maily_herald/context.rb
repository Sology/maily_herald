module MailyHerald
  class Context
    class Drop < Liquid::Drop
      def initialize attributes, item
        @attributes = attributes
        @item = item
      end

      def has_key?(name)
        name = name.to_sym

        @attributes.has_key? name
      end

      def invoke_drop name
        name = name.to_sym

        if @attributes.has_key? name
          #@attributes[name].try(:call, @item)
          @attributes[name].call(@item)
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
    end

    def model
      @model ||= @scope.call.table.engine
    end

    def scope &block
      if block_given?
        @scope = block
        extend_model 
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

    def each &block
      @scope.call.each do |item|
        drop = Drop.new(@attributes, item)
        block.call(item, drop)
      end
    end

    def drop_for item
      Drop.new(@attributes, item)
    end

    private

    def extend_model
      #unless model.included_modules.include?(MailyHerald::ModelExtensions::TriggerPatch)
        #model.send(:include, MailyHerald::ModelExtensions::TriggerPatch)
      #end
    end
  end
end
