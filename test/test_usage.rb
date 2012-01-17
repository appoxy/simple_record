# These ones take longer to run

require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require File.join(File.dirname(__FILE__), "./test_base")
require "yaml"
require 'aws'
require_relative 'models/my_model'
require_relative 'models/my_child_model'
require 'active_support'

# Tests for SimpleRecord
#

class TestUsage < TestBase

  def test_aaa_first_at_bat
    MyModel.delete_domain
    MyModel.create_domain
  end

  # ensures that it uses next token and what not
  def test_select_usage_logging

    SimpleRecord.log_usage(:select=>{:filename=>"/tmp/selects.csv", :format=>:csv, :lines_between_flushes=>2})

    num_made = 10
    num_made.times do |i|
      mm = MyModel.create(:name=>"Gravis", :age=>i, :cool=>true)
    end

    mms = MyModel.find(:all, :conditions=>["name=?", "Gravis"],:consistent_read=>true)
    mms = MyModel.find(:all, :conditions=>["name=?", "Gravis"], :order=>"name desc",:consistent_read=>true)
    mms = MyModel.find(:all, :conditions=>["name=? and age>?", "Gravis", 3], :order=>"name desc",:consistent_read=>true)
                
    SimpleRecord.close_usage_log(:select)
  end

  def test_zzz_last_at_bat
    MyModel.delete_domain
  end

end

