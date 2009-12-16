
module SimpleRecord::Callbacks
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

    end

    def before_destroy()
    end

    def after_destroy()
    end
end
