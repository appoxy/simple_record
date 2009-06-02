require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")

class MyModel < SimpleRecord::Base

  has_attributes :name, :age, :cool
  are_ints :age
  are_booleans :cool

end