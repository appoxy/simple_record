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
class TestGlobalOptions < TestBase

    def setup

        SimpleRecord::Base.set_domain_prefix("someprefix_")

        super
    end

    def test_domain_prefix

#        SimpleRecord::Base.set_domain_prefix("someprefix_")

        p = Person.create(:name=>"my prefix name")

        sleep 1

         sdb_atts = @@sdb.select("select * from someprefix_people")
        puts 'sdb_atts=' + sdb_atts.inspect

         @@sdb.delete_domain("someprefix_people") # doing it here so it's done before assertions might fail

        assert sdb_atts[:items].size == 1, "hmmm, not size 1: " + sdb_atts[:items].size.to_s



    end

end
