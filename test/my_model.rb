require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")

class MyModel < SimpleRecord::Base

    has_strings :name, :nickname
    has_ints :age
    has_booleans :cool
    has_dates :birthday


    #callbacks
    before_create :set_nickname

    def set_nickname
        self.nickname = name if self.nickname.blank?
    end

    def validate
        errors.add("name", "can't be empty.") if name.blank?
    end



    def atts
        @@attributes
    end

end