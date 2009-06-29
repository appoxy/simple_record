require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")

class MyModel < SimpleRecord::Base

    has_attributes :name
    has_ints :age
    has_booleans :cool
    has_dates :created, :updated, :birthday


end