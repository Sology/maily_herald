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

				#@attributes[name].try(:call, @item)
				@attributes[name].call(@item)
			end

			alias :[] :invoke_drop
		end

		attr_accessor :entity

		def scope &block
			if block_given?
				@scope = block
			else
				@scope
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

		def each &block
			@scope.call.each do |item|
				drop = Drop.new(@attributes, item)
				block.call(item, drop)
			end
		end

		def drop_for item
			Drop.new(@attributes, item)
		end
	end
end
