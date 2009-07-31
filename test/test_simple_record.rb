require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'right_aws'
require 'my_model'
require 'my_child_model'

class TestSimpleRecord < Test::Unit::TestCase

    def setup
        @config = YAML::load(File.open(File.expand_path("~/.amazon/simple_record_tests.yml")))
        #puts @config.inspect
        SimpleRecord.establish_connection(@config['amazon']['access_key'], @config['amazon']['secret_key'], :port=>80, :protocol=>"http")
        SimpleRecord::Base.set_domain_prefix("simplerecord_tests_")
        SimpleRecord.stats.clear
    end

    def teardown
        SimpleRecord.close_connection()
    end


    def test_count
        count = MyModel.find(:count) # select 1
        assert count > 0

        mms = MyModel.find(:all) # select 2
        assert mms.size > 0 # select 3
        assert mms.size == count # skipped
        assert SimpleRecord.stats.selects == 3, "should have been 3 select, but was actually #{SimpleRecord.stats.selects}" # count should not have been called twice

        count = MyModel.find(:count, :conditions=>["name=?", "Travis"])
        assert count > 0

        mms = MyModel.find(:all, :conditions=>["name=?", "Travis"])
        assert mms.size > 0
        assert mms.size == count

    end

    def test_attributes_correct

        #MyModel.defined_attributes.each do |a|
        #
        #end
        #MyChildModel.defined_attributes.inspect

    end


    # ensures that it uses next token and what not
    def test_big_result
        #110.times do |i|
        #    MyModel
        #end
        #rs = MyModel.find(:all, :limit=>300)
        #rs.each do |x|
        #   puts 'x=' + x.id
        #end
    end
end
