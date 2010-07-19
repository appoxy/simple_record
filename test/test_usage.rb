# These ones take longer to run

require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require File.join(File.dirname(__FILE__), "./test_base")
require "yaml"
require 'aws'
require 'my_model'
require 'my_child_model'
require 'active_support'

# Tests for SimpleRecord
#

class TestUsage < TestBase


    # ensures that it uses next token and what not
    def test_select_usage_logging

        SimpleRecord.log_usage(:select=>{:filename=>"/mnt/selects.csv", :format=>:csv, :lines_between_flushes=>2})

        num_made = 10
        num_made.times do |i|
            mm = MyModel.create(:name=>"Travis", :age=>i, :cool=>true)
        end

        mms = MyModel.find(:all, :conditions=>["name=?", "Travis"])
        mms = MyModel.find(:all, :conditions=>["name=?", "Travis"], :order=>"name desc")
        mms = MyModel.find(:all, :conditions=>["name=? and age>?", "Travis", 3], :order=>"name desc")
                

        SimpleRecord.close_usage_log(:select)

    end


end

