module SimpleRecord
    module Attributes
# For all things related to defining attributes.


        def self.included(base)
            #puts 'Callbacks included in ' + base.inspect
=begin
            instance_eval <<-endofeval

         def self.defined_attributes
                #puts 'class defined_attributes'
                @attributes ||= {}
                @attributes
            endendofeval
            endofeval
=end

        end


        module ClassMethods


            def defined_attributes
                @attributes ||= {}
                @attributes
            end

            def has_attributes(*args)
                has_attributes2(args)
            end

            def has_attributes2(args, options_for_all={})
#            puts 'args=' + args.inspect
#            puts 'options_for_all = ' + options_for_all.inspect
                args.each do |arg|
                    arg_options = {}
                    if arg.is_a?(Hash)
                        # then attribute may have extra options
                        arg_options = arg
                        arg         = arg_options[:name].to_sym
                    end
                    type = options_for_all[:type] || :string
                    attr = Attribute.new(type, arg_options)
                    defined_attributes[arg] = attr if defined_attributes[arg].nil?

                    # define reader method
                    arg_s = arg.to_s # to get rid of all the to_s calls
                    send(:define_method, arg) do
                        ret = get_attribute(arg)
                        return ret
                    end

                    # define writer method
                    send(:define_method, arg_s+"=") do |value|
                        set(arg, value)
                    end

                    define_dirty_methods(arg_s)
                end
            end

            def define_dirty_methods(arg_s)
                # Now for dirty methods: http://api.rubyonrails.org/classes/ActiveRecord/Dirty.html
                # define changed? method
                send(:define_method, arg_s + "_changed?") do
                    @dirty.has_key?(sdb_att_name(arg_s))
                end

                # define change method
                send(:define_method, arg_s + "_change") do
                    old_val = @dirty[sdb_att_name(arg_s)]
                    [old_val, get_attribute(arg_s)]
                end

                # define was method
                send(:define_method, arg_s + "_was") do
                    old_val = @dirty[sdb_att_name(arg_s)]
                    old_val
                end
            end

            def has_strings(*args)
                has_attributes(*args)
            end

            def has_ints(*args)
                has_attributes(*args)
                are_ints(*args)
            end

            def has_floats(*args)
                has_attributes(*args)
                are_floats(*args)
            end

            def has_dates(*args)
                has_attributes(*args)
                are_dates(*args)
            end

            def has_booleans(*args)
                has_attributes(*args)
                are_booleans(*args)
            end

            def are_ints(*args)
                #    puts 'calling are_ints: ' + args.inspect
                args.each do |arg|
                    defined_attributes[arg].type = :int
                end
            end

            def are_floats(*args)
                #    puts 'calling are_ints: ' + args.inspect
                args.each do |arg|
                    defined_attributes[arg].type = :float
                end
            end

            def are_dates(*args)
                args.each do |arg|
                    defined_attributes[arg].type = :date
                end
            end

            def are_booleans(*args)
                args.each do |arg|
                    defined_attributes[arg].type = :boolean
                end
            end

            def has_clobs(*args)
                has_attributes2(args, :type=>:clob)

            end

            def has_virtuals(*args)
                @@virtuals = args
                args.each do |arg|
                    #we just create the accessor functions here, the actual instance variable is created during initialize
                    attr_accessor(arg)
                end
            end

            # One belongs_to association per call. Call multiple times if there are more than one.
            #
            # This method will also create an {association)_id method that will return the ID of the foreign object
            # without actually materializing it.
            #
            # options:
            #     :class_name=>"User" - to change the default class to use
            def belongs_to(association_id, options = {})
                arg                     = association_id
                arg_s                   = arg.to_s
                arg_id                  = arg.to_s + '_id'
                attribute               = Attribute.new(:belongs_to, options)
                defined_attributes[arg] = attribute

                # todo: should also handle foreign_key http://74.125.95.132/search?q=cache:KqLkxuXiBBQJ:wiki.rubyonrails.org/rails/show/belongs_to+rails+belongs_to&hl=en&ct=clnk&cd=1&gl=us
                #    puts "arg_id=#{arg}_id"
                #        puts "is defined? " + eval("(defined? #{arg}_id)").to_s
                #        puts 'atts=' + @attributes.inspect

                # Define reader method
                send(:define_method, arg) do
                    return get_attribute(arg)
                end


                # Define writer method
                send(:define_method, arg.to_s + "=") do |value|
                    set(arg, value)
                end


                # Define ID reader method for reading the associated objects id without getting the entire object
                send(:define_method, arg_id) do
                    get_attribute_sdb(arg_s)
                end

                # Define writer method for setting the _id directly without the associated object
                send(:define_method, arg_id + "=") do |value|
#                rb_att_name = arg_s # n2 = name.to_s[0, name.length-3]
                    set(arg_id, value)
#                if value.nil?
#                    self[arg_id] = nil unless self[arg_id].nil? # if it went from something to nil, then we have to remember and remove attribute on save
#                else
#                    self[arg_id] = value
#                end
                end

                send(:define_method, "create_"+arg.to_s) do |*params|
                    newsubrecord=eval(arg.to_s.classify).new(*params)
                    newsubrecord.save
                    arg_id      = arg.to_s + '_id'
                    self[arg_id]=newsubrecord.id
                end

                define_dirty_methods(arg_s)
            end

            def has_many(*args)
                args.each do |arg|
                    #okay, this creates an instance method with the pluralized name of the symbol passed to belongs_to
                    send(:define_method, arg) do
                        #when called, the method creates a new, very temporary instance of the Activerecordtosdb_subrecord class
                        #It is passed the three initializers it needs:
                        #note the first parameter is just a string by time new gets it, like "user"
                        #the second and third parameters are still a variable when new gets it, like user_id
                        return eval(%{Activerecordtosdb_subrecord_array.new('#{arg}', self.class.name ,id)})
                    end
                end
                #Disclaimer: this whole funciton just seems crazy to me, and a bit inefficient. But it was the clearest way I could think to do it code wise.
                #It's bad programming form (imo) to have a class method require something that isn't passed to it through it's variables.
                #I couldn't pass the id when calling find, since the original find doesn't work that way, so I was left with this.
            end

            def has_one(*args)

            end


        end

        @@virtuals=[]

        def self.handle_virtuals(attrs)
            @@virtuals.each do |virtual|
                #we first copy the information for the virtual to an instance variable of the same name
                eval("@#{virtual}=attrs['#{virtual}']")
                #and then remove the parameter before it is passed to initialize, so that it is NOT sent to SimpleDB
                eval("attrs.delete('#{virtual}')")
            end
        end


        def set(name, value, dirtify=true)
#            puts "SET #{name}=#{value.inspect}" if SimpleRecord.logging?
#            puts "self=" + self.inspect
            attname      = name.to_s # default attname
            name         = name.to_sym
            att_meta     = get_att_meta(name)
            store_rb_val = false
            if att_meta.nil?
                # check if it ends with id and see if att_meta is there
                ends_with = name.to_s[-3, 3]
                if ends_with == "_id"
#                    puts 'ends with id'
                    n2       = name.to_s[0, name.length-3]
#                    puts 'n2=' + n2
                    att_meta = defined_attributes_local[n2.to_sym]
#                    puts 'defined_attributes_local=' + defined_attributes_local.inspect
                    attname  = name.to_s
                    attvalue = value
                    name     = n2.to_sym
                end
                return if att_meta.nil?
            else
                if att_meta.type == :belongs_to
                    ends_with = name.to_s[-3, 3]
                    if ends_with == "_id"
                        att_name = name.to_s
                        attvalue = value
                    else
                        attname      = name.to_s + '_id'
                        attvalue     = value.nil? ? nil : value.id
                        store_rb_val = true
                    end
                elsif att_meta.type == :clob
                    make_dirty(name, value) if dirtify
                    @lobs[name] = value
                    return
                else
                    attname  = name.to_s
                    attvalue = att_meta.init_value(value)
#                  attvalue = value
                    #puts 'converted ' + value.inspect + ' to ' + attvalue.inspect
                end
            end
            attvalue = strip_array(attvalue)
            make_dirty(name, attvalue) if dirtify
#            puts "ARG=#{attname.to_s} setting to #{attvalue}"
            sdb_val              = ruby_to_sdb(name, attvalue)
#            puts "sdb_val=" + sdb_val.to_s
            @attributes[attname] = sdb_val
#            attvalue = wrap_if_required(name, attvalue, sdb_val)
#            puts 'attvalue2=' + attvalue.to_s

            if store_rb_val
                @attributes_rb[name.to_s] = value
            else
                @attributes_rb.delete(name.to_s)
            end

        end


        def set_attribute_sdb(name, val)
            @attributes[sdb_att_name(name)] = val
        end


        def get_attribute_sdb(name)
            name = name.to_sym
            ret  = strip_array(@attributes[sdb_att_name(name)])
            return ret
        end

        # Since SimpleDB supports multiple attributes per value, the values are an array.
        # This method will return the value unwrapped if it's the only, otherwise it will return the array.
        def get_attribute(name)
#            puts "get_attribute #{name}"
            # Check if this arg is already converted
            name_s   = name.to_s
            name     = name.to_sym
            att_meta = get_att_meta(name)
#            puts "att_meta for #{name}: " + att_meta.inspect
            if att_meta && att_meta.type == :clob
                ret = @lobs[name]
#                puts 'get_attribute clob ' + ret.inspect
                if ret
                    if ret.is_a? RemoteNil
                        return nil
                    else
                        return ret
                    end
                end
                # get it from s3
                unless new_record?
                    begin
                        ret                        = s3_bucket.get(s3_lob_id(name))
#                        puts 'got from s3 ' + ret.inspect
                        SimpleRecord.stats.s3_gets += 1
                    rescue Aws::AwsError => ex
                        if ex.include? /NoSuchKey/
                            ret = nil
                        else
                            raise ex
                        end
                    end

                    if ret.nil?
                        ret = RemoteNil.new
                    end
                end
                @lobs[name] = ret
                return nil if ret.is_a? RemoteNil
                return ret
            else
                @attributes_rb = {} unless @attributes_rb # was getting errors after upgrade.
                ret = @attributes_rb[name_s] # instance_variable_get(instance_var)
                return ret unless ret.nil?
                return nil if ret.is_a? RemoteNil
                ret                    = get_attribute_sdb(name)
#                p ret
                ret                    = sdb_to_ruby(name, ret)
#                p ret
                @attributes_rb[name_s] = ret
                return ret
            end

        end


        private
        def set_attributes(atts)
            atts.each_pair do |k, v|
                set(k, v)
            end
        end


        # Holds information about an attribute
        class Attribute
            attr_accessor :type, :options

            def initialize(type, options=nil)
                @type    = type
                @options = options
            end

            def init_value(value)
                return value if value.nil?
                ret = value
                case self.type
                    when :int
                        if value.is_a? Array
                            ret = value.collect { |x| x.to_i }
                        else
                            ret = value.to_i
                        end
                end
                ret
            end

        end

    end
end