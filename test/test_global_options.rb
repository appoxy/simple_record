require 'test/unit'
require_relative "../lib/simple_record"
require "yaml"
require 'aws'
require_relative 'models/my_model'
require_relative 'models/my_child_model'
require 'active_support/core_ext'
require_relative 'test_base'


class Person < SimpleRecord::Base
    has_strings :name, :i_as_s
    has_ints :age
end
class TestGlobalOptions < TestBase

    def setup
        super
    end

    def test_domain_prefix

        SimpleRecord::Base.set_domain_prefix("someprefix_")

        p = Person.create(:name=>"my prefix name")

        sleep 1

        sdb_atts = @@sdb.select("select * from someprefix_people")

        @@sdb.delete_domain("someprefix_people") # doing it here so it's done before assertions might fail

        assert_equal sdb_atts[:items].size, 1

    end

    def test_created_col_and_updated_col
        reset_connection(:created_col=>"created_at", :updated_col=>"updated_at")

        p = Person.create(:name=>"my prefix name")
        sleep 1

        sdb_atts = @@sdb.select("select * from simplerecord_tests_people")

        @@sdb.delete_domain("simplerecord_tests_people")

        items = sdb_atts[:items][0]
        first = nil
        items.each_pair do |k, v|
            first = v
            break
        end

        assert_nil first["created"]
        assert_not_nil first["created_at"]

        # put this back to normal so it doesn't interfere with other tests
        reset_connection(:created_col=>"created", :updated_col=>"updated")
    end
end
