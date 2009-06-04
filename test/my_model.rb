require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")

class MyModel < SimpleRecord::Base

    has_attributes :created, :updated, :name, :age, :cool, :birthday
    are_ints :age
    are_booleans :cool
    are_dates :created, :updated, :birthday


end