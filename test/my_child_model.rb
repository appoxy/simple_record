require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require 'my_model'

class MyChildModel < SimpleRecord::Base
    belongs_to :my_model
    has_attributes :name
end

#
#
#puts 'word'
#
#mm = MyModel.new
#puts 'word2'
#
#mcm = MyChildModel.new
#
#puts 'mcm instance methods=' + MyChildModel.instance_methods(true).inspect
##puts 'mcm=' + mcm.instance_methods(false)
#puts 'mcm class vars = ' + mcm.class.class_variables.inspect
#puts mcm.class == MyChildModel
#puts 'saved? ' + mm.save.to_s
#puts mm.errors.inspect
