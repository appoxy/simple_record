require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'right_aws'
require 'my_model'
require 'my_child_model'
require 'active_support'


class Person < SimpleRecord::Base
    has_strings :name
    has_ints :age
end
class DirtyTest < Test::Unit::TestCase
    
    def setup
        @config = YAML::load(File.open(File.join(File.dirname(__FILE__), "test-config.yml")))
        @@sdb = RightAws::SdbInterface.new(@config['amazon']['access_key'], @config['amazon']['secret_key'], {:connection_mode => :per_request, :protocol => "http", :port => 80})

        SimpleRecord.establish_connection(@config['amazon']['access_key'], @config['amazon']['secret_key'], :connection_mode=>:single)
        SimpleRecord::Base.set_domain_prefix("simplerecord_tests_")
        
        Person.create_domain
        @person = Person.new(:name => 'old', :age => '70')
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
    end
    
    def test_reverted_changes_are_not_dirty
        @person.name = "new"
        assert @person.changed?
        assert @person.name_changed?
        
        @person.name = "old"
        assert !@person.changed?
        assert !@person.name_changed?
    end
end