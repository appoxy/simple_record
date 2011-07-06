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

  def test_virtuals
    model = MyBaseModel.new(:v1=>'abc', :base_string=>'what')
    assert model.v1 == 'abc', "model.v1=" + model.v1.inspect

  end

end
