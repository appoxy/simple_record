

require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'right_aws'
require 'my_model'
require 'my_child_model'

x = 0
puts SimpleRecord::Base.pad_and_offset(x)

x = 1
puts SimpleRecord::Base.pad_and_offset(x)

