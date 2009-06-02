require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")

class MyChildModel
    belongs_to :my_model
    has_attributes :name
end