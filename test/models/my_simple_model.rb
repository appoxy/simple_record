require File.expand_path(File.dirname(__FILE__) + "/../../lib/simple_record")
require_relative 'my_base_model'
require_relative 'my_sharded_model'

class MySimpleModel < SimpleRecord::Base

  has_strings :name, :nickname, :s1, :s2
  has_ints :age, :save_count
  has_booleans :cool
  has_dates :birthday, :date1, :date2, :date3


end
