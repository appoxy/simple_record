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

class TestResultsArray < TestBase


    # ensures that it uses next token and what not
    def test_big_result
        i = TestHelpers.clear_out_my_models
        num_made = 110
        num_made.times do |i|
            mm = MyModel.create(:name=>"Travis", :age=>i, :cool=>true)
        end
        rs = MyModel.find(:all) # should get 100 at a time
        assert rs.size == num_made
        i = 0
        rs.each do |x|
            #puts 'x=' + x.id
            i+=1
        end
        assert i == num_made
    end
    
    
end