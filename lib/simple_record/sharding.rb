module SimpleRecord

    module Sharding

        def self.included(base)
#            base.extend ClassMethods
        end

        module ClassMethods

            def shard(options=nil)
                @sharding_options = options
            end

            def sharding_options
                @sharding_options
            end

            def is_sharded?
                @sharding_options
            end

            def find_sharded(*params)
                puts 'find_sharded ' + params.inspect

                options = params.size > 1 ? params[1] : {}

                if options[:shard] # User specified shard.
                    shard   = options[:shard]
                    domains = shard.is_a?(Array) ? (shard.collect { |x| prefix_shard_name(x) }) : [ prefix_shard_name(shard)]
                else
                    domains = sharded_domains
                end
#                puts "sharded_domains=" + domains.inspect

                single = false
                case params.first
                    when nil then
                        raise "Invalid parameters passed to find: nil."
                    when :all, :first, :count
                        # nada
                    else # single id
                        unless params.first.is_a?(Array)
                            single = true
                        end
                end

                results = ShardedResults.new(params)
                domains.each do |d|
                    p2               = params.dup
                    op2              = options.dup
                    op2[:from]       = d
                    op2[:shard_find] = true
                    p2[1]            = op2
                    rs               = find(*p2)
                    if params.first == :first || single
                        return rs if rs
                    else
                        results.add_results rs
                    end
                end
                puts 'results=' + results.inspect
                if params.first == :first || single
                    # Then we found nothing by this point so return nil
                    return nil
                elsif params.first == :count
                    return results.sum_count
                end
                results

            end

            def shards
                send(sharding_options[:shards])
            end

            def prefix_shard_name(s)
                "#{domain}_#{s}"
            end


            def sharded_domains
                sharded_domains = []
                shard_names     = shards
                shard_names.each do |s|
                    sharded_domains << prefix_shard_name(s)
                end
                sharded_domains
            end
        end

        def sharded_domain
#            puts 'getting sharded_domain'
            options        = self.class.sharding_options
#            val = self.send(options[:on])
#            puts "val=" + val.inspect
#            shards = options[:shards] # is user passed in static array of shards
#            if options[:shards].is_a?(Symbol)
#                shards = self.send(shards)
#            end
            sharded_domain = "#{domain}_#{self.send(options[:map])}"
#            puts "sharded_domain=" + sharded_domain.inspect
            sharded_domain
        end

        class ShardedResults
            include Enumerable

            def initialize(params)
                @params         = params
                @options        = params.size > 1 ? params[1] : {}
                @results_arrays = []
            end

            def add_results(rs)
#        puts 'adding results=' + rs.inspect
                @results_arrays << rs
            end

            # only used for count queries
            def sum_count
                x = 0
                @results_arrays.each do |rs|
                    x += rs if rs
                end
                x
            end

            def <<(val)
                raise "Not supported."
            end

            def element_at(index)
                @results_arrays.each do |rs|
                    if rs.size > index
                        return rs[index]
                    end
                    index -= rs.size
                end
            end

            def [](*i)
                if i.size == 1
                    #            puts '[] i=' + i.to_s
                    index = i[0]
                    return element_at(index)
                else
                    offset = i[0]
                    rows   = i[1]
                    ret    = []
                    x      = offset
                    while x < (offset+rows)
                        ret << element_at(x)
                        x+=1
                    end
                    ret
                end
            end

            def first
                @results_arrays.first.first
            end

            def last
                @results_arrays.last.last
            end

            def empty?
                @results_arrays.each do |rs|
                    return false if !rs.empty?
                end
                true
            end

            def include?(obj)
                @results_arrays.each do |rs|
                    x = rs.include?(obj)
                    return true if x
                end
                false
            end

            def size
                return @size if @size
                s = 0
                @results_arrays.each do |rs|
                    #            puts 'rs=' + rs.inspect
                    #            puts 'rs.size=' + rs.size.inspect
                    s += rs.size
                end
                @size = s
                s
            end

            def length
                return size
            end

            def each(&blk)
                i = 0
                @results_arrays.each do |rs|
                    rs.each(&blk)
                    i+=1
                end
            end

            # for will_paginate support
            def total_pages
                # puts 'total_pages'
                # puts  @params[1][:per_page].to_s
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


            def delete(item)
                raise "Not supported"
            end

            def delete_at(index)
                raise "Not supported"
            end

        end

        # Some hashing algorithms
        module Hashing
            def self.sdbm_hash(str, len=str.length)
#                puts 'sdbm_hash ' + str.inspect
                hash = 0
                len.times { |i|
                    c    = str[i]
#                    puts "c=" + c.class.name + "--" + c.inspect + " -- " + c.ord.inspect
                    c    = c.ord
                    hash = c + (hash << 6) + (hash << 16) - hash
                }
#                puts "hash=" + hash.inspect
                return hash
            end
        end
    end

end
