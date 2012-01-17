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

class TestResultsArray < TestBase


    # ensures that it uses next token and what not
    def test_big_result
        MyModel.delete_domain
        MyModel.create_domain
        SimpleRecord.stats.clear
        num_made = 110
        num_made.times do |i|
            mm = MyModel.create(:name=>"Travis big_result #{i}", :age=>i, :cool=>true)
        end
        assert SimpleRecord.stats.saves == num_made, "SimpleRecord.stats.saves should be #{num_made}, is #{SimpleRecord.stats.saves}"
        SimpleRecord.stats.clear # have to clear them again, as each save above created a select (in pre/post actions)
        rs = MyModel.find(:all,:consistent_read=>true) # should get 100 at a time
        assert rs.size == num_made, "rs.size should be #{num_made}, is #{rs.size}"
        i = 0
        rs.each do |x|
            i+=1
        end
        assert SimpleRecord.stats.selects == 3, "SimpleRecord.stats.selects should be 3, is #{SimpleRecord.stats.selects}" # one for count.
        assert i == num_made, "num_made should be #{i}, is #{num_made}"
        # running through all the results twice to ensure it works properly after lazy loading complete.
        SimpleRecord.stats.clear
        i = 0
        rs.each do |x|
            #puts 'x=' + x.id
            i+=1
        end
        assert SimpleRecord.stats.selects == 0, "SimpleRecord.stats.selects should be 0, is #{SimpleRecord.stats.selects}" # one for count.
        assert i == num_made, "num_made should be #{i}, is #{num_made}"
    end

    def test_limit
        SimpleRecord.stats.clear
        rs = MyModel.find(:all, :per_token=>2500,:consistent_read=>true)
        assert rs.size == 110, "rs.size should be 110, is #{rs.size}"
        assert SimpleRecord.stats.selects == 1, "SimpleRecord.stats.selects is #{SimpleRecord.stats.selects}"

    end
    
    
end
