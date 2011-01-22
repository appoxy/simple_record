require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require_relative 'my_base_model'
require_relative 'my_sharded_model'

class MyModel < MyBaseModel

    has_strings :name, :nickname, :s1, :s2
    has_ints :age, :save_count
    has_booleans :cool
    has_dates :birthday, :date1, :date2, :date3

    belongs_to :my_sharded_model

    has_clobs :clob1, :clob2

    #callbacks
    before_create :set_nickname

    before_save :bump_save_count

    def set_nickname
        self.nickname = name if self.nickname.blank?
    end

    def bump_save_count
#        puts 'save_count=' + save_count.to_s
        if save_count.nil?
            self.save_count = 1
        else
            self.save_count += 1
        end
#         puts 'save_count=' + self.save_count.to_s
    end

    def validate
        errors.add("name", "can't be empty.") if name.blank?
    end

    def validate_on_create
        errors.add("save_count", "should be zero.") if !save_count.blank? && save_count > 0
    end

    def validate_on_update
#        puts 'save_count = ' + save_count.to_s
        errors.add("save_count", "should not be zero.") if save_count.blank? || save_count == 0
    end

    def atts
        @@attributes
    end

end



class SingleClobClass < SimpleRecord::Base

    sr_config :single_clob=>true

    has_strings :name

    has_clobs :clob1, :clob2
end
