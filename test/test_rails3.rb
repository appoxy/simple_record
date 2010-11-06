require 'test/unit'
require 'active_model'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require File.join(File.dirname(__FILE__), "./test_base")
require "yaml"
require 'aws'
require_relative 'my_model'
require_relative 'my_child_model'
require_relative 'model_with_enc'

# To test things related to rails 3 like ActiveModel usage.
class TestRails3 < TestBase

    def test_active_model_defined

        my_model = MyModel.new

        assert (defined?(MyModel.model_name))


    end

end