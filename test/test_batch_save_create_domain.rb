gem 'test-unit'
require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require_relative "test_base"
require "yaml"
require 'aws'
require_relative 'my_model'
require_relative 'my_child_model'
require_relative 'model_with_enc'
require_relative 'my_simple_model'

# Tests for SimpleRecord
#

# Store this in a different table
class MyNonexistentDomainModel < MySimpleModel
  
end

class TestSimpleRecord < TestBase

  def test_batch_save_with_no_domain
    MyNonexistentDomainModel.delete_domain
    items = []
    mm = MyNonexistentDomainModel.new
    mm.name = "Travis"
    mm.age = 32
    mm.cool = true
    items << mm
    mm = MyNonexistentDomainModel.new
    mm.name = "Tritt"
    mm.age = 44
    mm.cool = false
    items << mm
    MyNonexistentDomainModel.batch_save(items)
    items.each do |item|
      puts 'id=' + item.id
      new_item = MyNonexistentDomainModel.find(item.id, :consistent_read => true)
      #puts 'new=' + new_item.inspect
      assert item.id == new_item.id
      assert item.name == new_item.name
      assert item.cool == new_item.cool
    end
  end

end
