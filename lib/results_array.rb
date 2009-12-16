module SimpleRecord

    #
    # We need to make this behave as if the full set were loaded into the array.
    class ResultsArray
        include Enumerable

        attr_reader :next_token, :clz, :params, :items, :i


        def initialize(clz=nil, params=[], items=[], next_token=nil)
            @clz = clz
            #puts 'class=' + clz.inspect
            @params = params
            if @params.size <= 1
                options = {}
                @params[1] = options
            end
            @items = items
            @currentset_items = items
            @next_token = next_token
            @i = 0
        end

        def << (val)
            @items << val
        end

        def [](*i)
            puts 'i.inspect=' + i.inspect
            puts i.size.to_s
            i.each do |x|
                puts 'x=' + x.inspect + " -- " + x.class.name
            end
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
            # puts 'SIZE count=' + @count.inspect
            # todo: if no next token, should use the array.size so we don't call count
            return @count if @count
            params_for_count = params.dup
            params_for_count[0] = :count
            #puts 'params_for_count=' + params_for_count.inspect
            @count = clz.find(*params_for_count)
            # puts '@count=' + @count.to_s
            @count
        end

        def length
            return size
        end

        def each(&blk)
            options = @params[1]
            limit = options[:limit]

            @currentset_items.each do |v|
#                puts @i.to_s
                yield v
                @i += 1
                if !limit.nil? && @i >= limit
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
                each(&blk)
            end
        end

        def load_next_token_set
            options = @params[1]
            options[:next_token] = @next_token
            res = @clz.find(*@params)
            @currentset_items = res.items # get the real items array from the ResultsArray
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

    end
end
