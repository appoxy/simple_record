# Only used if ActiveModel is not present

module SimpleRecord
    module Rails2


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


        def invalid?
            !valid?
        end

    end
end