module SimpleRecord

    #
    # We need to make this behave as if the full set were loaded into the array.
    class ResultsArray
        include Enumerable

        attr_reader :next_token, :clz, :params, :items, :index, :box_usage, :request_id


        def initialize(clz=nil, params=[], results=nil, next_token=nil)
            @clz    = clz
            #puts 'class=' + clz.inspect
            @params = params
            if @params.size <= 1
                options    = {}
                @params[1] = options
            end
            @items            = results[:items]
            @currentset_items = results[:items]
            @next_token       = next_token
#            puts 'bu=' + results[:box_usage]
            @box_usage        = results[:box_usage].to_f
            @request_id       = results[:request_id]
            @options          = @params[1]
            if @options[:page]
                load_to(@options[:per_page] * @options[:page])
                @start_at = @options[:per_page] * (@options[:page] - 1)
            end
            @index = 0
            # puts 'RESULTS_ARRAY=' + self.inspect
        end

        def << (val)
            @items << val
        end

        def [](*i)
#            puts 'i.inspect=' + i.inspect
#            puts i.size.to_s
#            i.each do |x|
#                puts 'x=' + x.inspect + " -- " + x.class.name
#            end
            if i.size == 1
                # either fixnum or range
                x = i[0]
                if x.is_a?(Fixnum)
                    load_to(x)
                else
                    # range
                    end_val = x.exclude_end? ? x.end-1 : x.end
                    load_to(end_val)
                end
            elsif i.size == 2
                # two fixnums
                end_val = i[0] + i[1]
                load_to(end_val)
            end
            @items[*i]
        end

        # Will load items from SimpleDB up to i.
        def load_to(i)
            return if @items.size >= i
            while @items.size < i && !@next_token.nil?
                load_next_token_set
            end
        end

        def first
            @items[0]
        end

        def last
            @items[@items.length-1]
        end

        def empty?
            @items.empty?
        end

        def include?(obj)
            @items.include?(obj)
        end

        def size
#             if @options[:per_page]
#                return @items.size - @start_at
#            end
            if @next_token.nil?
                return @items.size
            end
            return @count if @count
#            puts '@params=' + @params.inspect
            params_for_count    = @params.dup
            params_for_count[0] = :count
            params_for_count[1] = params_for_count[1].dup # for deep clone
            params_for_count[1].delete(:limit)
            params_for_count[1].delete(:per_token)
            params_for_count[1][:called_by] = :results_array

            #       puts '@params2=' + @params.inspect
            # puts 'params_for_count=' + params_for_count.inspect
            @count = clz.find(*params_for_count)
#            puts '@count=' + @count.to_s
            @count
        end

        def length
            return size
        end

        def each(&blk)
            each2((@start_at || 0), &blk)
        end

        def each2(i, &blk)
            options = @params[1]
#            puts 'options=' + options.inspect
            limit   = options[:limit]
            #        puts 'limit=' + limit.inspect

            if i > @items.size
                i = @items.size
            end
            range = i..@items.size
#            puts 'range=' + range.inspect
            @items[range].each do |v|
#                puts "i=" + i.to_s
                yield v
                i += 1
                @index += 1
                if !limit.nil? && i >= limit
                    return
                end
            end
            return if @clz.nil?

            # no more items, but is there a next token?
            unless @next_token.nil?
                #puts 'finding more items...'
                #puts 'params in block=' + params.inspect
                #puts "i from results_array = " + @i.to_s

                load_next_token_set
                each2(i, &blk)
            end
        end

        # for will_paginate support
        def total_pages
            #puts 'total_pages'
#            puts  @params[1][:per_page].to_s
            return 1 if @params[1][:per_page].nil?
            ret = (size / @params[1][:per_page].to_f).ceil
            #puts 'ret=' + ret.to_s
            ret
        end

        def current_page
            return query_options[:page] || 1
        end

        def query_options
            return @options
        end

        def total_entries
            return size
        end

        # Helper method that is true when someone tries to fetch a page with a
        # larger number than the last page. Can be used in combination with flashes
        # and redirecting.
        def out_of_bounds?
            current_page > total_pages
        end

        # Current offset of the paginated collection. If we're on the first page,
        # it is always 0. If we're on the 2nd page and there are 30 entries per page,
        # the offset is 30. This property is useful if you want to render ordinals
        # side by side with records in the view: simply start with offset + 1.
        def offset
            (current_page - 1) * per_page
        end

        # current_page - 1 or nil if there is no previous page
        def previous_page
            current_page > 1 ? (current_page - 1) : nil
        end

        # current_page + 1 or nil if there is no next page
        def next_page
            current_page < total_pages ? (current_page + 1) : nil
        end

        def load_next_token_set
            options              = @params[1]
            options[:next_token] = @next_token
            options[:called_by] = :results_array
            res                  = @clz.find(*@params)
            @currentset_items    = res.items # get the real items array from the ResultsArray
            @currentset_items.each do |item|
                @items << item
            end
            @next_token = res.next_token
        end

        def delete(item)
            @items.delete(item)
        end

        def delete_at(index)
            @items.delete_at(index)
        end


        # A couple json serialization methods copied from active_support
        def as_json(options = nil) #:nodoc:
            # use encoder as a proxy to call as_json on all elements, to protect from circular references
            encoder = options && options[:encoder] || ActiveSupport::JSON::Encoding::Encoder.new(options)
            map { |v| encoder.as_json(v) }
        end

        def encode_json(encoder) #:nodoc:
            # we assume here that the encoder has already run as_json on self and the elements, so we run encode_json directly
            "[#{map { |v| v.encode_json(encoder) } * ','}]"
        end

    end
end
