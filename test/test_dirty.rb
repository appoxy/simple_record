require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'aws'
require 'my_model'
require 'my_child_model'
require 'active_support'
require 'test_base'


class Person < SimpleRecord::Base
    has_strings :name, :i_as_s
    has_ints :age
end
class DirtyTest < TestBase

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

    def test_same_value_are_not_dirty
        @person.name = "old"

        assert !@person.changed?
        assert !@person.name_changed?

        @person.age = 70
        puts 'age_change2=' + @person.age_change.inspect
        assert !@person.changed?
        assert !@person.age_changed?
    end

    def test_reverted_changes_are_not_dirty
        @person.name = "new"
        assert @person.changed?
        assert @person.name_changed?

        @person.name = "old"
        assert !@person.changed?
        assert !@person.name_changed?

        @person.age = 15
        assert @person.changed?
        assert @person.age_changed?

        @person.age = 70
        puts 'age_change2=' + @person.age_change.inspect
        assert !@person.changed?
        assert !@person.age_changed?
    end

    def test_storing_int_as_string
        @person.i_as_s = 5
        assert @person.changed?
        assert @person.i_as_s_changed?
        @person.save

        sleep 2

        @person.i_as_s = 5
        puts 'i_as_s_changed=' + @person.i_as_s_change.inspect
        # Maybe this should fail? What do we expect this behavior to be?
#        assert !@person.changed?
#        assert !@person.i_as_s_changed?

    end
end