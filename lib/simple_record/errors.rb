module SimpleRecord

    class SimpleRecordError < StandardError
        
    end


    class RecordInvalid < SimpleRecordError
        attr_accessor :record

        def initialize(record)
            @record = record
        end
    end
    
end

