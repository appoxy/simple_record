require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require 'my_base_model'

class MyModel < MyBaseModel

    has_strings :name, :nickname
    has_ints :age, :save_count
    has_booleans :cool
    has_dates :birthday


    #callbacks
    before_create :set_nickname

    before_save :bump_save_count

    def set_nickname
        self.nickname = name if self.nickname.blank?
    end

    def bump_save_count
        puts 'save_count=' + save_count.to_s
        if save_count.nil?
            self.save_count = 1
        else
            self.save_count += 1
        end
         puts 'save_count=' + self.save_count.to_s
    end

    def validate
        errors.add("name", "can't be empty.") if name.blank?
    end

    def validate_on_create
        errors.add("save_count", "should be zero.") if !save_count.blank? && save_count > 0
    end

    def validate_on_update
        puts 'save_count = ' + save_count.to_s
        errors.add("save_count", "should not be zero.") if save_count.blank? || save_count == 0
    end

    def atts
        @@attributes
    end

end