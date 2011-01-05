module SimpleRecord

    class SimpleRecordError < StandardError

    end


    class RecordNotSaved < SimpleRecordError
        attr_accessor :record

        def initialize(record=nil)
            @record = record
            super("Validation failed: #{@record.errors.full_messages.join(", ")}")
        end
    end

    class RecordNotFound < SimpleRecordError

    end

    class Error
        attr_accessor :base, :attribute, :type, :message, :options

        def initialize(base, attribute, message, options = {})
          self.base      = base
          self.attribute = attribute
          self.message   = message
        end

        def message
          # When type is a string, it means that we do not have to do a lookup, because
          # the user already sent the "final" message.
          generate_message
        end

        def full_message
          attribute.to_s == 'base' ? message : generate_full_message()
        end

        alias :to_s :message

        def generate_message(options = {})
            @message
        end

        def generate_full_message(options = {})
            "#{attribute.to_s} #{message}"
        end
    end

    class SimpleRecord_errors
        attr_reader :errors

        def initialize(*params)
            super(*params)
            @errors={}
        end

        def add_to_base(msg)
            add(:base, msg)
        end

        def add(attribute, message, options = {})
            # options param note used; just for drop in compatibility with ActiveRecord
            error, message = message, nil if message.is_a?(Error)
            @errors[attribute.to_s] ||= []
            @errors[attribute.to_s] << (error || Error.new(@base, attribute, message, options))
        end

        def length
            return @errors.length
        end

        alias count length
        alias size length

        def full_messages
            @errors.values.inject([]) do |full_messages, errors|
                full_messages + errors.map { |error| error.full_message }
            end
        end

        def clear
            @errors.clear
        end

        def empty?
            @errors.empty?
        end

        def on(attribute)
            attribute = attribute.to_s
            return nil unless @errors.has_key?(attribute)
            errors = @errors[attribute].map(&:to_s)
            errors.size == 1 ? errors.first : errors
        end

        alias :[] :on

        def on_base
            on(:base)
        end
    end

end

