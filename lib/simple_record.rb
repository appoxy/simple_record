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
# RightAws::ActiveSdb.establish_connection(AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY)
# # Save an object
# mm = MyModel.new
# mm.name = "Travis"
# mm.age = 32
# mm.save
# id = mm.id
# # Get the object back
# mm2 = MyModel.select(id)
# puts 'got=' + mm2.name + ' and he/she is ' + mm.age.to_s + ' years old'



require 'right_aws'
require 'sdb/active_sdb'

module SimpleRecord

    VERSION = '1.0.8'

    class Base < RightAws::ActiveSdb::Base

        attr_accessor :errors
        @@domain_prefix = ''
        @domain_name_for_class = nil

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
            @@domain_prefix = prefix
        end

        # Same as set_table_name
        def self.set_table_name(table_name)
            set_domain_name table_name
        end

        # Sets the domain name for this class
        def self.set_domain_name(table_name)
            # puts 'setting domain name for class ' + self.inspect + '=' + table_name
            @domain_name_for_class = table_name
            super
        end

        def self.get_domain_name
            # puts 'returning domain_name=' + @domain_name_for_class.to_s
            return @domain_name_for_class
        end


        def domain
            super # super.domain
        end

        def self.domain
            return self.get_domain_name unless self.get_domain_name.nil?
            d = super
            domain_name_for_class = @@domain_prefix + d.to_s
            self.set_domain_name(domain_name_for_class)
            domain_name_for_class
        end

        #this bit of code creates a "run_blank" function for everything value in the @@callbacks array.
        #this function can then be inserted in the appropriate place in the save, new, destroy, etc overrides
        #basically, this is how we recreate the callback functions
        @@callbacks=["before_save", "before_create", "after_create", "before_update", "after_update", "after_save", "after_destroy"]
        @@callbacks.each do |callback|
            #we first have to make an initialized array for each of the callbacks, to prevent problems if they are not called
            eval %{
        @@#{callback}_names=[]

        def self.#{callback}(*args)
        args.each do |arg|
          @@#{callback}_names << arg.to_s if @@#{callback}_names.index(arg.to_s).nil?
        end
#      asdf    @@#{callback}_names=args.map{|arg| arg.to_s}
      end

        def run_#{callback}
          @@#{callback}_names.each { |name|
          unless eval(name)
            return false
          end
          }
          return true
        end
    }
        end

        def self.has_attributes(*args)
            @@attributes = args
            args.each do |arg|
                # define reader method
                send :define_method, arg do
                    ret = nil
                    if self[arg.to_s].class==Array
                        if self[arg.to_s].length==1
                            ret = self[arg.to_s][0]
                        else
                            ret = self[arg.to_s]
                        end
                    else
                        ret = self[arg.to_s]
                    end
                    return nil if ret.nil?
                    return un_offset_if_int(arg, ret)
                end

                # define writer method
                method_name = (arg.to_s+"=")
                send(:define_method, method_name) do |value|
                    self[arg.to_s]=value#      end
                end
            end
        end

        @@ints = []
        def self.are_ints(*args)
            #    puts 'calling are_ints: ' + args.inspect
            args.each do |arg|
                # todo: maybe @@ints and @@dates should be maps for quicker lookups
                @@ints << arg if @@ints.index(arg).nil?
            end
#    @@ints = args
            #    puts 'ints=' + @@ints.inspect
        end

        @@dates = []
        def self.are_dates(*args)
            args.each do |arg|
                @@dates << arg if @@dates.index(arg).nil?
            end
#    @@dates = args
            #    puts 'dates=' + @@dates.inspect
        end

        @@booleans = []
        def self.are_booleans(*args)
            args.each do |arg|
                @@booleans << arg if @@booleans.index(arg).nil?
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

        @@belongs_to_map = {}
        # One belongs_to association per call. Call multiple times if there are more than one.
        #
        # This method will also create an {association)_id method that will return the ID of the foreign object
        # without actually materializing it.
        def self.belongs_to(association_id, options = {})
            @@belongs_to_map[association_id] = options
            arg = association_id
            arg_id = arg.to_s + '_id'

            # todo: should also handle foreign_key http://74.125.95.132/search?q=cache:KqLkxuXiBBQJ:wiki.rubyonrails.org/rails/show/belongs_to+rails+belongs_to&hl=en&ct=clnk&cd=1&gl=us
            #    puts "arg_id=#{arg}_id"
            #        puts "is defined? " + eval("(defined? #{arg}_id)").to_s
            #        puts 'atts=' + @attributes.inspect

            # Define reader method
            send(:define_method, arg) do
                options2 = @@belongs_to_map[arg]
                class_name = options2[:class_name] || arg.to_s[0...1].capitalize + arg.to_s[1...arg.to_s.length]
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
                        to_eval = "#{class_name}.find(@attributes['#{arg_id}'][0], :auto_load=>true)"
#      puts 'to eval=' + to_eval
                        begin
                            ret = eval(to_eval) # (defined? #{arg}_id)
                        rescue RightAws::ActiveSdb::ActiveSdbError
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

            # Define reader ID method
            send(:define_method, arg_id) do
                if !@attributes[arg_id].nil? && @attributes[arg_id].size > 0 && @attributes[arg_id][0] != nil && @attributes[arg_id][0] != ''
                    return @attributes[arg_id][0]
                end
                return nil
            end

            # Define writer method
            send(:define_method, arg.to_s + "=") do |value|
                arg_id = arg.to_s + '_id'
                if value.nil?
                    self[arg_id]=nil unless self[arg_id].nil? # if it went from something to nil, then we have to remember and remove attribute on save
                else
                    self[arg_id]=value.id
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

        has_attributes :created, :updated
        before_create :set_created, :set_updated
        before_update :set_updated
        are_dates :created, :updated

        def set_created
#    puts 'SETTING CREATED'
            #    @created = DateTime.now
            self[:created] = DateTime.now
#    @tester = 'some test value'
            #    self[:tester] = 'some test value'
        end

        def set_updated
#    puts 'SETTING UPDATED'
            #    @updated = DateTime.now
            self[:updated] = DateTime.now
#    @tester = 'some test value updated'
        end

        def initialize(*params)
            if params[0]
                #we have to handle the virtuals. Right now, this assumes that all parameters are passed from inside an array
                #this is the usually the case when the parameters are passed passed via POST and obtained from the params array
                @@virtuals.each do |virtual|
                    #we first copy the information for the virtual to an instance variable of the same name
                    eval("@#{virtual}=params[0]['#{virtual}']")
                    #and then remove the parameter before it is passed to initialize, so that it is NOT sent to SimpleDB
                    eval("params[0].delete('#{virtual}')")
                end
                super(*params)
            else
                super()
            end
            @errors=SimpleRecord_errors.new
        end


        @@offset = 9223372036854775808
        @@padding = 20

        def self.pad_and_offset(x)
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
                if x.is_a? DateTime
                    x_str = x.new_offset(0).iso8601
                else
                    x_str = x.getutc.iso8601
                end
               #  puts 'utc=' + x_str
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

        @create_domain_called = false

        def save(*params)
            #    puts 'SAVING: ' + self.inspect
            is_create = self[:id].nil?
            ok = pre_save(*params)
            if ok
                begin
                    #        puts 'is frozen? ' + self.frozen?.to_s + ' - ' + self.inspect
                    to_delete = get_atts_to_delete
                    if super(*params)
#          puts 'SAVED super'
                        self.class.cache_results(self)
                        delete_niled(to_delete)
                        if run_after_save && is_create ? run_after_create : run_after_update
                            return true
                        else
                            #I thought about calling destroy here, but rails doesn't behave that way, so neither will I
                            return false
                        end
                    else
                        return false
                    end
                rescue RightAws::AwsError
                    # puts "RESCUED in save: " + $!
                    if (domain_ok($!))
                        if !@create_domain_called
                            @create_domain_called = true
                            save(*params)
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

        def pad_and_offset_ints_to_sdb()
            if !@@ints.nil?
                for i in @@ints
#          puts 'int encoding: ' + i.to_s
                    if !self[i.to_s].nil?
#            puts 'before: ' + self[i.to_s].inspect
                        #            puts @attributes.inspect
                        #            puts @attributes[i.to_s].inspect
                        arr = @attributes[i.to_s]
                        arr.collect!{ |x| self.class.pad_and_offset(x) }
                        @attributes[i.to_s] = arr
#            puts 'after: ' + @attributes[i.to_s].inspect
                    else
                        #            puts 'was nil'
                    end
                end
            end
        end
         def convert_dates_to_sdb()
            if !@@dates.nil?
                for i in @@dates
#          puts 'int encoding: ' + i.to_s
                    if !self[i.to_s].nil?
#            puts 'before: ' + self[i.to_s].inspect
                        #            puts @attributes.inspect
                        #            puts @attributes[i.to_s].inspect
                        arr = @attributes[i.to_s]
                        #puts 'padding date=' + i.to_s
                        arr.collect!{ |x| self.class.pad_and_offset(x) }
                        @attributes[i.to_s] = arr
#            puts 'after: ' + @attributes[i.to_s].inspect
                    else
                        #            puts 'was nil'
                    end
                end
            end
        end

        def pre_save(*params)
            if respond_to?('validate')
                validate
#      puts 'AFTER VALIDATIONS, ERRORS=' + errors.inspect
                if (!@errors.nil? && @errors.length > 0 )
#        puts 'THERE ARE ERRORS, returning false'
                    return false
                end
            end

            is_create = self[:id].nil?
            ok = respond_to?('before_save') ? before_save : true
            if ok
                if is_create && respond_to?('before_create')
                    ok = before_create
                elsif !is_create && respond_to?('before_update')
                    ok = before_update
                end
            end
            if ok
                ok = run_before_save && is_create ? run_before_create : run_before_update
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
            to_delete = []
            @attributes.each do |key, value|
                #      puts 'value=' + value.inspect
                if value.nil? || (value.is_a?(Array) && value.size == 0)
                    to_delete << key
                end
            end
            return to_delete
        end

        # Run pre_save on each object, then runs batch_put_attributes
        # Returns
        def self.batch_save(objects)
            results = []
            to_save = []
            if objects && objects.size > 0
                objects.each do |o|
                    ok = o.pre_save
                    raise "Pre save failed on object with id = " + o.id if !ok
                    results << ok
                    next if !ok
                    o.pre_save2
                    to_save << RightAws::SdbInterface::Item.new(o.id, o.attributes, true)
                end
            end
            connection.batch_put_attributes(domain, to_save)
            results
        end

        #
        # Usage: ClassName.delete id
        # todo: move to RightAWS
        #
        def self.delete(id)
            connection.delete_attributes(domain, id)
        end

        def delete_niled(to_delete)
            if to_delete.size > 0
#      puts 'Deleting attributes=' + to_delete.inspect
                delete_attributes to_delete
            end
        end

        def un_offset_if_int(arg, x)
            if !@@ints.nil?
                for i in @@ints
#        puts 'unpadding: ' + i.to_s
                    # unpad and unoffset
                    if i == arg
#          puts 'unoffsetting ' + x.to_s
                        x = un_offset_int(x)
                    end
                end
            end
            if !@@dates.nil?
                for d in @@dates
#        puts 'converting created: ' + self['created'].inspect
                    if d == arg
                        x = to_date(x)
                    end
#          if !self[d].nil?
#            self[d].collect!{ |d2|
#              if d2.is_a?(String)
#                DateTime.parse(d2)
#              else
#                d2
#              end
#            }
#          end
#        puts 'after=' + self['created'].inspect
                end
            end
            if !@@booleans.nil?
                for b in @@booleans
#        puts 'converting created: ' + self['created'].inspect
                    if b == arg
                        x = to_bool(x)
                    end
#          if !self[d].nil?
#            self[d].collect!{ |d2|
#              if d2.is_a?(String)
#                DateTime.parse(d2)
#              else
#                d2
#              end
#            }
#          end
#        puts 'after=' + self['created'].inspect
                end
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
                x == "true"
            else
                x
            end
        end


        def un_offset_int(x)
            if x.is_a?(String)
                x2 = x.to_i
#            puts 'to_i=' + x2.to_s
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
            if !@@ints.nil?
                for i in @@ints
#        puts 'unpadding: ' + i.to_s
                    # unpad and unoffset

                    unpad(i, @attributes)
                end
            end
        end

        def reload
            super()
#    puts 'decoding...'

=begin
This is done on getters now
 if !@@dates.nil?
        for d in @@dates
#        puts 'converting created: ' + self['created'].inspect
          if !self[d].nil?
            self[d].collect!{ |d2|
              if d2.is_a?(String)
                DateTime.parse(d2)
              else
                d2
              end
            }
          end
#        puts 'after=' + self['created'].inspect
        end
      end
=end

#      unpad_self
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

        def self.find(*params)
            reload=true
            first=false
            all=false
            select=false
            select_attributes=[]

            if params.size > 0
                all = params[0] == :all
                first = params[0] == :first
            end


            # Pad and Offset number attributes
            options = params[1]
#    puts 'options=' + options.inspect
            convert_condition_params(options)

#    puts 'after collect=' + params.inspect

            results = all ? [] : nil
            begin
                results=super(*params)
                cache_results(results)
            rescue RightAws::AwsError, RightAws::ActiveSdb::ActiveSdbError
                puts "RESCUED: " + $!
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

        @@regex_no_id = /.*Couldn't find.*with ID.*/
        def self.select(*params)
            first=false
            all=false
            select=false
            select_attributes=[]

            if params.size > 0
                all = params[0] == :all
                first = params[0] == :first
            end

            options = params[1]
            convert_condition_params(options)

            results = all ? [] : nil
            begin
                results=super(*params)
                cache_results(results)
            rescue RightAws::AwsError, RightAws::ActiveSdb::ActiveSdbError
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

        def self.convert_condition_params(options)
            if !options.nil? && options.size > 0
                conditions = options[:conditions]
                if !conditions.nil? && conditions.size > 1
                    # all after first are values
                    conditions.collect! { |x|
                        self.pad_and_offset(x)
                    }
                end
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
#        puts 'caching result at ' + cache_key + ': ' + results.inspect
                    @@cache_store.write(cache_key, results, :expires_in =>10*60)
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
            return @@domain_prefix + self.class.name.tableize
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

        def each(*params, &block)
            return load.each(*params){|record| block.call(record)}
        end

        def find_all(*params)
            find(:all, *params)
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
end
