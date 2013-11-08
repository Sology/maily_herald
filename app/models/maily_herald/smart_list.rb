module MailyHerald
	class SmartList
		if Rails.env.development?
			PAGE_SIZES = [3, 10, 20, 50, 100]
		else
			PAGE_SIZES = [10, 20, 50, 100]
		end

		attr_reader :name, :collection, :options, :per_page, :page, :sort_attr, :sort_order, :sort_extra, :partial, :count

		def initialize name, collection, options = {}
			@name = name

			@options = {
				:param_names  => {                  # param names
					:page             => "#{@name}_page".to_sym,
					:per_page         => "#{@name}_per_page".to_sym,
					:sort_attr        => "#{@name}_sort_attr".to_sym,
					:sort_order       => "#{@name}_sort_order".to_sym,
					:sort_extra       => "#{@name}_sort_extra".to_sym,
				},
				:partial            => @name,       # smart list partial name
				:array              => false,       # controls whether smart list should be using arrays or AR collections
				:max_count          => nil,         # limit number of rows
				:unlimited_per_page => false,       # allow infinite page size
				:sort               => true,        # allow sorting
				:paginate           => true,        # allow pagination
				:href               => nil,         # set smart list target url (in case when different than current url)
				:default_sort_attr  => nil,         # default sort by
				:memorize_per_page  => false,
			}.merge!(options)

			if @options[:array]
				@collection = collection.to_a
			else 
				@collection = collection
			end
		end

		def setup params, cookies
			@page = params[param_names[:page]]
			@per_page = !params[param_names[:per_page]] || params[param_names[:per_page]].empty? ? (@options[:memorize_per_page] && cookies[param_names[:per_page]].to_i > 0 ? cookies[param_names[:per_page]].to_i : PAGE_SIZES.first) : params[param_names[:per_page]].to_i
			@sort_attr = params[param_names[:sort_attr]] || @options[:default_sort_attr]
			@sort_order = ["asc", "desc"].include?(params[param_names[:sort_order]]) ? params[param_names[:sort_order]] : "desc"
			@sort_extra = params[param_names[:sort_extra]]

			cookies[param_names[:per_page]] = @per_page if @options[:memorize_per_page]

			@count = @collection.size

			if @options[:array]
				@collection = @collection.sort do |x, y|
					xval = x
					yval = y
					@sort_attr.split(".").each do |m|
						xval = xval.try(m)
						yval = yval.try(m)
					end
					xval = xval.upcase if xval.is_a?(String)
					yval = yval.upcase if yval.is_a?(String)

					if xval.nil? || yval.nil?
						xval.nil? ? 1 : -1
					else
						if @sort_order == "asc"
							(xval <=> yval) || (xval && !yval ? 1 : -1)
						else
							(yval <=> xval) || (yval && !xval ? 1 : -1)
						end
					end
				end if @options[:sort] && @sort_attr && !@sort_attr.empty?
				if @options[:paginate] && @per_page > 0
					@collection = Kaminari.paginate_array(@collection).page(@page).per(@per_page)
					if @collection.length == 0
						@collection = @collection.page(@collection.num_pages)
					end
				end
			else
				@collection = @collection.order("#{@sort_attr} #{@sort_order}") if @options[:sort] && @sort_attr && !@sort_attr.empty? && @sort_order
				if @options[:paginate] && @per_page > 0
					@collection = @collection.page(@page).per(@per_page)
				end
			end
		end

		def partial
			@options[:partial]
		end

		def param_names
			@options[:param_names]
		end

		def unlimited_per_page?
			!!@options[:unlimited_per_page]
		end

		def max_count
			@options[:max_count]
		end

		def href
			@options[:href]
		end

		def all_params
			ap = {}
			@options[:param_names].each do |k, v|
				ap[v] = self.send(k)
			end
			ap
		end
	end
end
