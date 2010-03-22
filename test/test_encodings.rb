require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'aws'
require 'my_model'
require 'my_child_model'
require 'active_support'
require 'test_base'


class Person < SimpleRecord::Base
    has_strings :name, :i_as_s
    has_ints :age
end
class TestEncodings < TestBase

    
end