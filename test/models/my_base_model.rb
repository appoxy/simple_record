require File.expand_path(File.dirname(__FILE__) + "/../../lib/simple_record")

class MyBaseModel < SimpleRecord::Base

  has_strings :base_string

  has_virtuals :v1


end
