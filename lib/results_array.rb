module SimpleRecord
    class ResultsArray

        attr_reader :next_token, :clz, :params, :items, :i

        def initialize(clz=nil, params=[], items=[], next_token=nil)
            @clz = clz
            #puts 'class=' + clz.inspect
            @params = params
            #puts 'params in ra=' + params.inspect
            @items = items
            @next_token = next_token
            @i = 0
        end

        def << (val)
            @items << val
        end

        def [](i)
            @items[i]
        end

        def size
            # puts 'SIZE count=' + @count.inspect
            return @count if @count
            params_for_count = params.dup
            params_for_count[0] = :count
            @count = clz.find(*params_for_count)
            # puts '@count=' + @count.to_s
            @count
        end

        def length
            return size
        end


        def each(&blk)
            limit = nil
            if params.size > 1
                options = params[1]
                limit = options[:limit]
            else
                options = {}
                params[1] = options
            end

            @items.each do |v|
                puts @i.to_s
                yield v
                @i += 1
                if !limit.nil? && @i >= limit
                    return
                end
            end
            # no more items, but is there a next token?
            return if clz.nil?

            unless next_token.nil?
                #puts 'finding more items...'
                #puts 'params in block=' + params.inspect
                options[:next_token] = next_token
                res = clz.find(*params)
                @items = res.items
                @next_token = res.next_token
                each(&blk)
            end
        end
    end
end

