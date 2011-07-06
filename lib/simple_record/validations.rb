# This is actually still used to continue support for this.
# ActiveModel does not work the same way so need to continue using this, will change name.

module SimpleRecord
  module Validations

#    if defined?(:valid?) # from ActiveModel
#      alias_method :am_valid?, :valid?
#    end

    def self.included(base)
#      puts 'Validations included ' + base.inspect
#      if defined?(ActiveModel)
#        base.class_eval do
#          alias_method :am_valid?, :valid?
#        end
#      end
    end

    module ClassMethods

      def uniques
        @uniques ||= {}
        @uniques
      end

        # only supporting single attr name right now
      def validates_uniqueness_of(attr)
        uniques[attr] = true
      end

    end

    def valid?
#      puts 'in rails2 valid?'
      errors.clear

      if respond_to?(:am_valid?)
        # And now ActiveModel validations too
        am_valid?
      end

        #            run_callbacks(:validate)
      validate
      validate_uniques

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


    def read_attribute_for_validation(key)
      @attributes[key.to_s]
    end

    def validate_uniques
      puts 'uniques=' + self.class.uniques.inspect
      self.class.uniques.each_pair do |k, v|
        val = self.send(k)
        puts 'val=' + val.inspect
        if val
          ret = self.class.find(:first, :conditions=>["#{k}=?", val])
          puts 'ret=' + ret.inspect
          if ret
            errors.add(k, "must be unique.")
          end
        end
      end
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


  end
end

