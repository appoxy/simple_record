module SimpleRecord

  # For Rails3 support
  module Callbacks3

#    def destroy #:nodoc:
#      _run_destroy_callbacks { super }
#    end
#
#    private
#
#    def create_or_update #:nodoc:
#      puts '3 create_or_update'
#      _run_save_callbacks { super }
#    end
#
#    def create #:nodoc:
#      puts '3 create'
#      _run_create_callbacks { super }
#    end
#
#    def update(*) #:nodoc:
#      puts '3 update'
#      _run_update_callbacks { super }
#    end
  end

  module Callbacks
    #this bit of code creates a "run_blank" function for everything value in the @@callbacks array.
    #this function can then be inserted in the appropriate place in the save, new, destroy, etc overrides
    #basically, this is how we recreate the callback functions
    @@callbacks=["before_validation", "before_validation_on_create", "before_validation_on_update",
                 "after_validation", "after_validation_on_create", "after_validation_on_update",
                 "before_save", "before_create", "before_update", "before_destroy",
                 "after_create", "after_update", "after_save",
                 "after_destroy"]

    def self.included(base)
      #puts 'Callbacks included in ' + base.inspect

#        puts "setup callbacks #{base.inspect}"
      base.instance_eval <<-endofeval

            def callbacks
                @callbacks ||= {}
                @callbacks
            end


      endofeval

      @@callbacks.each do |callback|
        base.class_eval <<-endofeval

         def run_#{callback}
            # puts 'CLASS CALLBACKS for ' + self.inspect + ' = ' + self.class.callbacks.inspect
            return true if self.class.callbacks.nil?
            cnames = self.class.callbacks['#{callback}']
            cnames = [] if cnames.nil?
            # cnames += super.class.callbacks['#{callback}'] unless super.class.callbacks.nil?
            # puts 'cnames for #{callback} = ' + cnames.inspect
            return true if cnames.nil?
            cnames.each { |name|
                #puts 'run_  #{name}'
              if eval(name) == false # nil should be an ok return, only looking for false
                return false
              end
          }
          # super.run_#{callback}
          return true
        end

        endofeval

        #this bit of code creates a "run_blank" function for everything value in the @@callbacks array.
        #this function can then be inserted in the appropriate place in the save, new, destroy, etc overrides
        #basically, this is how we recreate the callback functions
        base.instance_eval <<-endofeval

#            puts 'defining callback=' + callback + ' for ' + self.inspect
            #we first have to make an initialized array for each of the callbacks, to prevent problems if they are not called

            def #{callback}(*args)
#                puts 'callback called in ' + self.inspect + ' with ' + args.inspect

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
    end

    def before_destroy()
    end

    def after_destroy()
    end


    def self.setup_callbacks(base)

    end

  end
end
