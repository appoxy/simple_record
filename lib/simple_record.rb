# Usage:
# require 'simple_record'
#
# class MyModel < SimpleRecord::Base
#
#   has_attributes :name, :age
#   are_ints :age
#
# end
#
# AWS_ACCESS_KEY_ID='XXXXX'
# AWS_SECRET_ACCESS_KEY='YYYYY'
# SimpleRecord.establish_connection(AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY)
#
## Save an object
# mm = MyModel.new
# mm.name = "Travis"
# mm.age = 32
# mm.save
# id = mm.id
# # Get the object back
# mm2 = MyModel.select(id)
# puts 'got=' + mm2.name + ' and he/she is ' + mm.age.to_s + ' years old'


require 'aws'
require 'sdb/active_sdb'
#require 'results_array' # why the heck isn't this picking up???
require File.expand_path(File.dirname(__FILE__) + "/results_array")
require File.expand_path(File.dirname(__FILE__) + "/stats")
require File.expand_path(File.dirname(__FILE__) + "/callbacks")

module SimpleRecord

    @@stats = SimpleRecord::Stats.new

    def self.stats
        @@stats
    end

    # Create a new handle to an Sdb account. All handles share the same per process or per thread
    # HTTP connection to Amazon Sdb. Each handle is for a specific account.
    # The +params+ are passed through as-is to Aws::SdbInterface.new
    # Params:
    #    { :server       => 'sdb.amazonaws.com'  # Amazon service host: 'sdb.amazonaws.com'(default)
    #      :port         => 443                  # Amazon service port: 80(default) or 443
    #      :protocol     => 'https'              # Amazon service protocol: 'http'(default) or 'https'
    #      :signature_version => '0'             # The signature version : '0' or '1'(default)
    #      :connection_mode  => :default         # options are
    #                                                  :default (will use best known safe (as in won't need explicit close) option, may change in the future)
    #                                                  :per_request (opens and closes a connection on every request to SDB)
    #                                                  :single (one thread across entire app)
    #                                                  :per_thread (one connection per thread)
    #                                                  :pool (uses a connection pool with a maximum number of connections - NOT IMPLEMENTED YET)
    #      :logger       => Logger Object        # Logger instance: logs to STDOUT if omitted
    def self.establish_connection(aws_access_key=nil, aws_secret_key=nil, params={})
        Aws::ActiveSdb.establish_connection(aws_access_key, aws_secret_key, params)
    end

    def self.close_connection()
        Aws::ActiveSdb.close_connection
    end

    class Base < Aws::ActiveSdb::Base

        include SimpleRecord::Callbacks


        def initialize(attrs={})
            # todo: Need to deal with objects passed in. iterate through belongs_to perhaps and if in attrs, set the objects id rather than the object itself

            #we have to handle the virtuals.
            @@virtuals.each do |virtual|
                #we first copy the information for the virtual to an instance variable of the same name
                eval("@#{virtual}=attrs['#{virtual}']")
                #and then remove the parameter before it is passed to initialize, so that it is NOT sent to SimpleDB
                eval("attrs.delete('#{virtual}')")
            end
            super
            @errors=SimpleRecord_errors.new
            @dirty = {}
        end


        # todo: move into Callbacks module
        #this bit of code creates a "run_blank" function for everything value in the @@callbacks array.
        #this function can then be inserted in the appropriate place in the save, new, destroy, etc overrides
        #basically, this is how we recreate the callback functions
        @@callbacks.each do |callback|
            instance_eval <<-endofeval

                #puts 'doing callback=' + callback + ' for ' + self.inspect
                #we first have to make an initialized array for each of the callbacks, to prevent problems if they are not called

                def #{callback}(*args)
                    #puts 'callback called in ' + self.inspect + ' with ' + args.inspect

                    #make_dirty(arg_s, value)
                    #self[arg.to_s]=value
                    #puts 'value in callback #{callback}=' + value.to_s
                    args.each do |arg|
                        cnames = callbacks['#{callback}']
                        #puts '\tcnames1=' + cnames.inspect + ' for class ' + self.inspect
                        cnames = [] if cnames.nil?
                        cnames << arg.to_s if cnames.index(arg.to_s).nil?
                        #puts '\tcnames2=' + cnames.inspect
                        callbacks['#{callback}'] = cnames
                    end
                end

            endofeval
        end
        #puts 'base methods=' + self.methods.inspect


        def self.inherited(base)
            #puts 'SimpleRecord::Base is inherited by ' + base.inspect
            setup_callbacks(base)

            base.has_dates :created, :updated
            base.before_create :set_created, :set_updated
            base.before_update :set_updated

        end

        def self.setup_callbacks(base)
            instance_eval <<-endofeval

                def callbacks
                    @callbacks ||= {}
                    @callbacks
                end

               def self.defined_attributes
                    #puts 'class defined_attributes'
                    @attributes ||= {}
                    @attributes
                end

            endofeval

            @@callbacks.each do |callback|
                class_eval <<-endofeval

             def run_#{callback}
#                puts 'CLASS CALLBACKS for ' + self.inspect + ' = ' + self.class.callbacks.inspect
                return true if self.class.callbacks.nil?
                cnames = self.class.callbacks['#{callback}']
                cnames = [] if cnames.nil?
                #cnames += super.class.callbacks['#{callback}'] unless super.class.callbacks.nil?
#                 puts 'cnames for #{callback} = ' + cnames.inspect
                return true if cnames.nil?
                cnames.each { |name|
                    #puts 'run_  #{name}'
                  if eval(name) == false # nil should be an ok return, only looking for false
                    return false
                  end
              }
                #super.run_#{callback}
              return true
            end

                endofeval
            end
        end


        # Holds information about an attribute
        class Attribute
            attr_accessor :type, :options

            def initialize(type)
                @type = type
            end

        end


        def defined_attributes_local
            #puts 'local defined_attributes'
            ret = self.class.defined_attributes
            ret.merge!(self.class.superclass.defined_attributes) if self.class.superclass.respond_to?(:defined_attributes)
        end


        attr_accessor :errors

        @domain_prefix = ''
        class << self;
            attr_accessor :domain_prefix;
        end

        #@domain_name_for_class = nil

        @@cache_store = nil
        # Set the cache to use
        def self.cache_store=(cache)
            @@cache_store = cache
        end

        def self.cache_store
            return @@cache_store
        end

        # If you want a domain prefix for all your models, set it here.
        def self.set_domain_prefix(prefix)
            #puts 'set_domain_prefix=' + prefix
            self.domain_prefix = prefix
        end

        # Same as set_table_name
        def self.set_table_name(table_name)
            set_domain_name table_name
        end

        # Sets the domain name for this class
        def self.set_domain_name(table_name)
            # puts 'setting domain name for class ' + self.inspect + '=' + table_name
            #@domain_name_for_class = table_name
            super
        end

=begin
 def self.get_domain_name
            # puts 'returning domain_name=' + @domain_name_for_class.to_s
            #return @domain_name_for_class
            return self.domain
        end

=end

        def domain
            super # super.domain
        end

        def self.domain
            #return self.get_domain_name unless self.get_domain_name.nil?
            d = super
            #puts 'in self.domain, d=' + d.to_s + ' domain_prefix=' + SimpleRecord::Base.domain_prefix.to_s
            domain_name_for_class = SimpleRecord::Base.domain_prefix + d.to_s
            #self.set_domain_name(domain_name_for_class)
            domain_name_for_class
        end


        # Since SimpleDB supports multiple attributes per value, the values are an array.
        # This method will return the value unwrapped if it's the only, otherwise it will return the array.
        def get_attribute(arg)
            arg = arg.to_s
            if self[arg].class==Array
                if self[arg].length==1
                    ret = self[arg][0]
                else
                    ret = self[arg]
                end
            else
                ret = self[arg]
            end
            ret
        end

        def make_dirty(arg, value)
            # todo: only set dirty if it changed
            #puts 'making dirty arg=' + arg.to_s + ' --- ' + @dirty.inspect
            @dirty[arg] = get_attribute(arg) # Store old value (not sure if we need it?)
            #puts 'end making dirty ' + @dirty.inspect
        end

        def self.has_attributes(*args)
            args.each do |arg|
                defined_attributes[arg] = SimpleRecord::Base::Attribute.new(:string) if defined_attributes[arg].nil?
                # define reader method
                arg_s = arg.to_s # to get rid of all the to_s calls
                send(:define_method, arg) do
                    ret = nil
                    ret = get_attribute(arg)
                    return nil if ret.nil?
                    return Base.un_offset_if_int(arg, ret)
                end

                # define writer method
                send(:define_method, arg_s+"=") do |value|
                    make_dirty(arg_s, value)
                    self[arg_s]=value
                end

                # Now for dirty methods: http://api.rubyonrails.org/classes/ActiveRecord/Dirty.html
                # define changed? method
                send(:define_method, arg_s + "_changed?") do
                    @dirty.has_key?(arg_s)
                end

                # define change method
                send(:define_method, arg_s + "_change") do
                    old_val = @dirty[arg_s]
                    return nil if old_val.nil?
                    [old_val, get_attribute(arg_s)]
                end

                # define was method
                send(:define_method, arg_s + "_was") do
                    old_val = @dirty[arg_s]
                    old_val
                end
            end
        end

        def self.has_strings(*args)
            has_attributes(*args)
        end

        def self.has_ints(*args)
            has_attributes(*args)
            are_ints(*args)
        end

        def self.has_dates(*args)
            has_attributes(*args)
            are_dates(*args)
        end

        def self.has_booleans(*args)
            has_attributes(*args)
            are_booleans(*args)
        end

        def self.are_ints(*args)
            #    puts 'calling are_ints: ' + args.inspect
            args.each do |arg|
                defined_attributes[arg].type = :int
            end
        end

        def self.are_dates(*args)
            args.each do |arg|
                defined_attributes[arg].type = :date
            end
        end

        def self.are_booleans(*args)
            args.each do |arg|
                defined_attributes[arg].type = :boolean
            end
        end

        @@virtuals=[]

        def self.has_virtuals(*args)
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
        def self.belongs_to(association_id, options = {})
            attribute = SimpleRecord::Base::Attribute.new(:belongs_to)
            defined_attributes[association_id] = attribute
            attribute.options = options
            #@@belongs_to_map[association_id] = options
            arg = association_id
            arg_s = arg.to_s
            arg_id = arg.to_s + '_id'

            # todo: should also handle foreign_key http://74.125.95.132/search?q=cache:KqLkxuXiBBQJ:wiki.rubyonrails.org/rails/show/belongs_to+rails+belongs_to&hl=en&ct=clnk&cd=1&gl=us
            #    puts "arg_id=#{arg}_id"
            #        puts "is defined? " + eval("(defined? #{arg}_id)").to_s
            #        puts 'atts=' + @attributes.inspect

            # Define reader method
            send(:define_method, arg) do
                attribute = defined_attributes_local[arg]
                options2 = attribute.options # @@belongs_to_map[arg]
                class_name = options2[:class_name] || arg.to_s[0...1].capitalize + arg.to_s[1...arg.to_s.length]

                # Camelize classnames with underscores (ie my_model.rb --> MyModel)
                class_name = class_name.camelize

                #      puts "attr=" + @attributes[arg_id].inspect
                #      puts 'val=' + @attributes[arg_id][0].inspect unless @attributes[arg_id].nil?
                ret = nil
                arg_id = arg.to_s + '_id'
                if !@attributes[arg_id].nil? && @attributes[arg_id].size > 0 && @attributes[arg_id][0] != nil && @attributes[arg_id][0] != ''
                    if !@@cache_store.nil?
                        arg_id_val = @attributes[arg_id][0]
                        cache_key = self.class.cache_key(class_name, arg_id_val)
#          puts 'cache_key=' + cache_key
                        ret = @@cache_store.read(cache_key)
#          puts 'belongs_to incache=' + ret.inspect
                    end
                    if ret.nil?
                        to_eval = "#{class_name}.find(@attributes['#{arg_id}'][0])"
#      puts 'to eval=' + to_eval
                        begin
                            ret = eval(to_eval) # (defined? #{arg}_id)
                        rescue Aws::ActiveSdb::ActiveSdbError
                            if $!.message.include? "Couldn't find"
                                ret = nil
                            else
                                raise $!
                            end
                        end

                    end
                end
#      puts 'ret=' + ret.inspect
                return ret
            end


            # Define writer method
            send(:define_method, arg.to_s + "=") do |value|
                arg_id = arg.to_s + '_id'
                if value.nil?
                    make_dirty(arg_id, nil)
                    self[arg_id]=nil unless self[arg_id].nil? # if it went from something to nil, then we have to remember and remove attribute on save
                else
                    make_dirty(arg_id, value.id)
                    self[arg_id]=value.id
                end
            end


            # Define ID reader method for reading the associated objects id without getting the entire object
            send(:define_method, arg_id) do
                if !@attributes[arg_id].nil? && @attributes[arg_id].size > 0 && @attributes[arg_id][0] != nil && @attributes[arg_id][0] != ''
                    return @attributes[arg_id][0]
                end
                return nil
            end

            # Define writer method for setting the _id directly without the associated object
            send(:define_method, arg_id + "=") do |value|
                if value.nil?
                    self[arg_id] = nil unless self[arg_id].nil? # if it went from something to nil, then we have to remember and remove attribute on save
                else
                    self[arg_id] = value
                end
            end

            send(:define_method, "create_"+arg.to_s) do |*params|
                newsubrecord=eval(arg.to_s.classify).new(*params)
                newsubrecord.save
                arg_id = arg.to_s + '_id'
                self[arg_id]=newsubrecord.id
            end
        end

        def self.has_many(*args)
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

        def self.has_one(*args)

        end

        def clear_errors
            @errors=SimpleRecord_errors.new
        end

        def []=(attribute, values)
            make_dirty(attribute, values)
            super
        end


        def set_created
#    puts 'SETTING CREATED'
            #    @created = DateTime.now
            self[:created] = DateTime.now
#    @tester = 'some test value'
            #    self[:tester] = 'some test value'
        end

        def set_updated
            #puts 'SETTING UPDATED'
            #    @updated = DateTime.now
            self[:updated] = DateTime.now
#    @tester = 'some test value updated'
        end


        @@offset = 9223372036854775808
        @@padding = 20
        @@date_format = "%Y-%m-%dT%H:%M:%S"; # Time to second precision

        def self.pad_and_offset(x) # Change name to something more appropriate like ruby_to_sdb
            # todo: add Float, etc
            #    puts 'padding=' + x.class.name + " -- " + x.inspect
            if x.kind_of? Integer
                x += @@offset
                x_str = x.to_s
                # pad
                x_str = '0' + x_str while x_str.size < 20
                return x_str
            elsif x.respond_to?(:iso8601)
                #  puts x.class.name + ' responds to iso8601'
                #
                # There is an issue here where Time.iso8601 on an incomparable value to DateTime.iso8601.
                # Amazon suggests: 2008-02-10T16:52:01.000-05:00
                #                  "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                #
                if x.is_a? DateTime
                    x_str = x.getutc.strftime(@@date_format)
                elsif x.is_a? Time
                    x_str = x.getutc.strftime(@@date_format)
                elsif x.is_a? Date
                    x_str = x.strftime(@@date_format)

                end
                return x_str
            else
                return x
            end
        end

        def domain_ok(ex)
            if (ex.message().index("NoSuchDomain") != nil)
                puts "Creating new SimpleDB Domain: " + domain
                self.class.create_domain
                return true
            end
            return false
        end

        def valid?
            errors.clear

#            run_callbacks(:validate)
            validate

            if new_record?
#                run_callbacks(:validate_on_create)
                validate_on_create
            else
#                run_callbacks(:validate_on_update)
                validate_on_update
            end

            errors.empty?
        end

        def new_record?
            # todo: new_record in activesdb should align with how we're defining a new record here, ie: if id is nil
            super
        end

        def invalid?
            !valid?
        end

        def validate
            true
        end

        def validate_on_create
            true
        end

        def validate_on_update
            true
        end

        @create_domain_called = false

        # Options:
        #   - :except => Array of attributes to NOT save
        #   - :dirty => true - Will only store attributes that were modified
        #
        def save(options={})
            #    puts 'SAVING: ' + self.inspect
            clear_errors
            # todo: decide whether this should go before pre_save or after pre_save? pre_save dirties "updated" and perhaps other items due to callbacks
            if options[:dirty] # Only used in simple_record right now
#                puts '@dirty=' + @dirty.inspect
                return true if @dirty.size == 0 # Nothing to save so skip it
                options[:dirty_atts] = @dirty
            end
            is_create = self[:id].nil?
            ok = pre_save(options)
            if ok
                begin
                    #        puts 'is frozen? ' + self.frozen?.to_s + ' - ' + self.inspect
#                    if options[:dirty] # Only used in simple_record right now
#                        puts '@dirty=' + @dirty.inspect
#                        return true if @dirty.size == 0 # Nothing to save so skip it
#                        options[:dirty_atts] = @dirty
#                    end
                    to_delete = get_atts_to_delete # todo: this should use the @dirty hash now
#                    puts 'done to_delete ' + to_delete.inspect
                    SimpleRecord.stats.puts += 1
                    if super(options)
#          puts 'SAVED super'
                        self.class.cache_results(self)
                        delete_niled(to_delete)
                        if (is_create ? run_after_create : run_after_update) && run_after_save
#                            puts 'all good?'
                            return true
                        else
                            return false
                        end
                    else
                        return false
                    end
                rescue Aws::AwsError
                    # puts "RESCUED in save: " + $!
                    if (domain_ok($!))
                        if !@create_domain_called
                            @create_domain_called = true
                            save(options)
                        else
                            raise $!
                        end
                    else
                        raise $!
                    end
                end
            else
                #@debug = "not saved"
                return false
            end
        end

        def save_with_validation!(options={})
            if valid?
                save
            else
                raise RecordInvalid.new(self)
            end
        end

        def pad_and_offset_ints_to_sdb()

            defined_attributes_local.each_pair do |name, att_meta|
#          puts 'int encoding: ' + i.to_s
                if att_meta.type == :int && !self[name.to_s].nil?
#            puts 'before: ' + self[i.to_s].inspect
                    #            puts @attributes.inspect
                    #            puts @attributes[i.to_s].inspect
                    arr = @attributes[name.to_s]
                    arr.collect!{ |x| self.class.pad_and_offset(x) }
                    @attributes[name.to_s] = arr
#            puts 'after: ' + @attributes[i.to_s].inspect
                end
            end
        end

        def convert_dates_to_sdb()

            defined_attributes_local.each_pair do |name, att_meta|
#          puts 'int encoding: ' + i.to_s
                if att_meta.type == :date && !self[name.to_s].nil?
#            puts 'before: ' + self[i.to_s].inspect
                    #            puts @attributes.inspect
                    #            puts @attributes[i.to_s].inspect
                    arr = @attributes[name.to_s]
                    #puts 'padding date=' + i.to_s
                    arr.collect!{ |x| self.class.pad_and_offset(x) }
                    @attributes[name.to_s] = arr
#            puts 'after: ' + @attributes[i.to_s].inspect
                else
                    #            puts 'was nil'
                end
            end
        end

        def pre_save(options)

            is_create = self[:id].nil?
            ok = run_before_validation && (is_create ? run_before_validation_on_create : run_before_validation_on_update)
            return false unless ok

            validate()

            is_create ? validate_on_create : validate_on_update
#      puts 'AFTER VALIDATIONS, ERRORS=' + errors.inspect
            if (!@errors.nil? && @errors.length > 0 )
#        puts 'THERE ARE ERRORS, returning false'
                return false
            end

            ok = run_after_validation && (is_create ? run_after_validation_on_create : run_after_validation_on_update)
            return false unless ok

            ok = respond_to?('before_save') ? before_save : true
            if ok
                if is_create && respond_to?('before_create')
                    ok = before_create
                elsif !is_create && respond_to?('before_update')
                    ok = before_update
                end
            end
            if ok
                ok = run_before_save && (is_create ? run_before_create : run_before_update)
            end
            if ok
#      puts 'ABOUT TO SAVE: ' + self.inspect
                # First we gotta pad and offset
                pad_and_offset_ints_to_sdb()
                convert_dates_to_sdb()
            end
            ok
        end

        def save_attributes(*params)
            ret = super(*params)
            if ret
                self.class.cache_results(self)
            end
            ret
        end

        def get_atts_to_delete
            # todo: this should use the @dirty hash now
            to_delete = []
            @attributes.each do |key, value|
#                puts 'key=' + key.inspect + ' value=' + value.inspect
                if value.nil? || (value.is_a?(Array) && value.size == 0) || (value.is_a?(Array) && value.size == 1 && value[0] == nil)
                    to_delete << key
                    @attributes.delete(key)
                end
            end
            return to_delete
        end

        # Run pre_save on each object, then runs batch_put_attributes
        # Returns
        def self.batch_save(objects, options={})
            results = []
            to_save = []
            if objects && objects.size > 0
                objects.each do |o|
                    ok = o.pre_save(options)
                    raise "Pre save failed on object [" + o.inspect + "]" if !ok
                    results << ok
                    next if !ok # todo: this shouldn't be here should it?  raises above
                    o.pre_save2
                    to_save << Aws::SdbInterface::Item.new(o.id, o.attributes, true)
                    if to_save.size == 25 # Max amount SDB will accept
                        connection.batch_put_attributes(domain, to_save)
                        to_save.clear
                    end
                end
            end
            connection.batch_put_attributes(domain, to_save) if to_save.size > 0
            results
        end

        #
        # Usage: ClassName.delete id
        # todo: move to Aws
        #
        def self.delete(id)
            connection.delete_attributes(domain, id)
        end

        def delete
            before_delete
            super
            after_delete
        end

        def delete_niled(to_delete)
#            puts 'to_delete=' + to_delete.inspect
            if to_delete.size > 0
#      puts 'Deleting attributes=' + to_delete.inspect
                delete_attributes to_delete
            end
        end

        def un_offset_if_int(arg, x)
            att_meta = defined_attributes_local[arg]
#          puts 'int encoding: ' + i.to_s
            if att_meta.type == :int
                x = Base.un_offset_int(x)
            elsif att_meta.type == :date
                x = to_date(x)
            elsif att_meta.type == :boolean
                x = to_bool(x)
            end
            x
        end


        def to_date(x)
            if x.is_a?(String)
                DateTime.parse(x)
            else
                x
            end

        end

        def to_bool(x)
            if x.is_a?(String)
                x == "true" || x == "1"
            else
                x
            end
        end


        def self.un_offset_int(x)
            if x.is_a?(String)
                x2 = x.to_i
            puts 'to_i=' + x2.to_s
                x2 -= @@offset
#            puts 'after subtracting offset='+ x2.to_s
                x2
            else
                x
            end
        end

        def unpad(i, attributes)
            if !attributes[i].nil?
#          puts 'before=' + self[i].inspect
                attributes[i].collect!{ |x|
                    un_offset_int(x)

                }
#          for x in self[i]
                #            x = self[i][0].to_i
                #            x -= @@offset
                #            self[i] = x
                #          end
            end
        end

        def unpad_self
            defined_attributes_local.each_pair do |name, att_meta|
                if att_meta.type == :int
                    unpad(name, @attributes)
                end
            end
        end

        def reload
            super()
        end

        def update_attributes(*params)
            return save_attributes(*params)
        end

        def destroy(*params)
            if super(*params)
                if run_after_destroy
                    return true
                else
                    return false
                end
            else
                return false
            end
        end

        def self.quote_regexp(a, re)
            a =~ re
            #was there a match?
            if $&
                before=$`
                middle=$&
                after=$'

                before =~ /'$/ #is there already a quote immediately before the match?
                unless $&
                    return "#{before}'#{middle}'#{quote_regexp(after, re)}" #if not, put quotes around the match
                else
                    return "#{before}#{middle}#{quote_regexp(after, re)}" #if so, assume it is quoted already and move on
                end
            else
                #no match, just return the string
                return a
            end
        end

        @@regex_no_id = /.*Couldn't find.*with ID.*/

        #
        # Usage:
        # Find by ID:
        #   MyModel.find(ID)
        #
        # Query example:
        #   MyModel.find(:all, :conditions=>["name = ?", name], :order=>"created desc", :limit=>10)
        #
        def self.find(*params)
            #puts 'params=' + params.inspect
            q_type = :all
            select_attributes=[]

            if params.size > 0
                q_type = params[0]
            end

            # Pad and Offset number attributes
            options = {}
            if params.size > 1
                options = params[1]
                #puts 'options=' + options.inspect
                #puts 'after collect=' + options.inspect
                convert_condition_params(options)
            end
#            puts 'params2=' + params.inspect

            results = q_type == :all ? [] : nil
            begin
                results=super(*params)
                #puts 'params3=' + params.inspect
                SimpleRecord.stats.selects += 1
                if q_type != :count
                    cache_results(results)
                    if results.is_a?(Array)
                        results = SimpleRecord::ResultsArray.new(self, params, results, next_token)
                    end
                end
            rescue Aws::AwsError, Aws::ActiveSdb::ActiveSdbError
                puts "RESCUED: " + $!.message
                if ($!.message().index("NoSuchDomain") != nil)
                    # this is ok
                elsif ($!.message() =~ @@regex_no_id)
                    results = nil
                else
                    raise $!
                end
            end
            return results
        end

        def self.select(*params)
            return find(*params)
        end

        def self.convert_condition_params(options)
            return if options.nil?
            conditions = options[:conditions]
            if !conditions.nil? && conditions.size > 1
                # all after first are values
                conditions.collect! { |x|
                    self.pad_and_offset(x)
                }
            end

        end

        def self.cache_results(results)
            if !@@cache_store.nil? && !results.nil?
                if results.is_a?(Array)
                    # todo: cache each result
                else
                    class_name = results.class.name
                    id = results.id
                    cache_key = self.cache_key(class_name, id)
                    #puts 'caching result at ' + cache_key + ': ' + results.inspect
                    @@cache_store.write(cache_key, results, :expires_in =>30)
                end
            end
        end

        def self.cache_key(class_name, id)
            return class_name + "/" + id.to_s
        end

        @@debug=""

        def self.debug
            @@debug
        end

        def self.sanitize_sql(*params)
            return ActiveRecord::Base.sanitize_sql(*params)
        end

        def self.table_name
            return domain
        end

        def changed
            return @dirty.keys
        end

        def changed?
            return @dirty.size > 0
        end

        def changes
            ret = {}
            #puts 'in CHANGES=' + @dirty.inspect
            @dirty.each_pair {|key, value| ret[key] = [value, get_attribute(key)]}
            return ret
        end

        def mark_as_old
            super
            @dirty = {}
        end

    end

    class SimpleRecord_errors
        def initialize(*params)
            super(*params)
            @errors=[]
        end

        def add_to_base(value)
            @errors+=[value]
        end

        def add(attribute, value)
            @errors+=["#{attribute.to_s} #{value}"]
        end

        def count
            return length
        end

        def length
            return @errors.length
        end

        def size
            return length
        end

        def full_messages
            return @errors
        end

        def clear
            @errors.clear
        end

        def empty?
            @errors.empty?
        end
    end

    class Activerecordtosdb_subrecord_array
        def initialize(subname, referencename, referencevalue)
            @subname=subname.classify
            @referencename=referencename.tableize.singularize + "_id"
            @referencevalue=referencevalue
        end

        # Performance optimization if you know the array should be empty

        def init_empty
            @records = []
        end

        def load
            if @records.nil?
                @records = find_all
            end
            return @records
        end

        def [](key)
            return load[key]
        end

        def <<(ob)
            return load << ob
        end

        def count
            return load.count
        end

        def size
            return count
        end

        def each(*params, &block)
            return load.each(*params){|record| block.call(record)}
        end

        def find_all(*params)
            find(:all, *params)
        end

        def empty?
            return load.empty?
        end

        def build(*params)
            params[0][@referencename]=@referencevalue
            eval(@subname).new(*params)
        end

        def create(*params)
            params[0][@referencename]=@referencevalue
            record = eval(@subname).new(*params)
            record.save
        end

        def find(*params)
            query=[:first, {}]
            #{:conditions=>"id=>1"}
            if params[0]
                if params[0]==:all
                    query[0]=:all
                end
            end

            if params[1]
                query[1]=params[1]
                if query[1][:conditions]
                    query[1][:conditions]=SimpleRecord::Base.sanitize_sql(query[1][:conditions])+" AND "+ SimpleRecord::Base.sanitize_sql(["#{@referencename} = ?", @referencevalue])
                    #query[1][:conditions]=Activerecordtosdb.sanitize_sql(query[1][:conditions])+" AND id='#{@id}'"
                else
                    query[1][:conditions]=["#{@referencename} = ?", @referencevalue]
                    #query[1][:conditions]="id='#{@id}'"
                end
            else
                query[1][:conditions]=["#{@referencename} = ?", @referencevalue]
                #query[1][:conditions]="id='#{@id}'"
            end

            return eval(@subname).find(*query)
        end

    end

    class SimpleRecordError < StandardError

    end

    class RecordInvalid < SimpleRecordError
        attr_accessor :record

        def initialize(record)
            @record = record
        end
    end
end

