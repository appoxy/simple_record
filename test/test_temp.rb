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

class TestSimpleRecord < TestBase

  def test_custom_id
    puts 'test_custom_id...'
    custom_id = "id-travis"
    mm = MyModel.new
    mm.id = custom_id
    mm.name = "Travis"
    mm.age = 32
    mm.cool = true
    mm.save
    sleep 1
    mm2 = MyModel.find(custom_id)
    puts 'mm2=' + mm2.inspect
    assert mm2.id == mm.id
  end

end
