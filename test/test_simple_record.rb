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
    end

    def teardown
        SimpleRecord.close_connection()
    end

    # ensures that it uses next token and what not
    def test_big_result
        #110.times do |i|
        #    MyModel
        #end
        rs = MyModel.find(:all, :limit=>300)
        rs.each do |x|
           puts 'x=' + x.id
        end
    end
end
