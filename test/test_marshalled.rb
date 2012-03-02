require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'aws'
require_relative 'models/my_model'
require_relative 'models/my_child_model'
require 'active_support'
require 'test_base'


class Person < SimpleRecord::Base
    has_strings :name, :i_as_s
    has_ints :age, :i2
end
class MarshalTest < TestBase

    def setup
        super

        Person.create_domain
        @person = Person.new(:name => 'old', :age => 70)
        @person.save

        assert !@person.changed?
        assert !@person.name_changed?
    end

    def teardown
        Person.delete_domain
        SimpleRecord.close_connection
    end

    def test_string_on_initialize
        p = Person.new(:name=>"Travis", :age=>5, :i2=>"6")
        assert p.name == "Travis"
        assert p.age == 5
        assert p.i2 == 6, "i2 == #{p.i2}"

        
    end

end

