module SimpleRecord

    class SimpleRecordError < StandardError
        
    end


    class RecordInvalid < SimpleRecordError
        attr_accessor :record

        def initialize(record)
            @record = record
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
    
end

