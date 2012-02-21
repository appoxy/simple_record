require File.expand_path(File.dirname(__FILE__) + "/../../lib/simple_record")

class MyTranslation < SimpleRecord::Base

  has_strings :name, :stage_name
  has_ints :age
  has_booleans :singer
  has_dates :birthday
  has_floats :weight, :height

end
