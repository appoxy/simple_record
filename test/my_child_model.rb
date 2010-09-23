require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require_relative 'my_model'

class MyChildModel < SimpleRecord::Base
    belongs_to :my_model
    belongs_to :x, :class_name=>"MyModel"
    has_attributes :name, :child_attr

end


=begin


puts 'word'

mm = MyModel.new
puts 'word2'

mcm = MyChildModel.new

puts 'mcm instance methods=' + MyChildModel.instance_methods(true).inspect
#puts 'mcm=' + mcm.instance_methods(false)
puts 'mcm class vars = ' + mcm.class.class_variables.inspect
puts mcm.class == MyChildModel
puts 'saved? ' + mm.save.to_s
puts mm.errors.inspect

puts "mm attributes=" + MyModel.defined_attributes.inspect
puts "mcm attributes=" + MyChildModel.defined_attributes.inspect

mcm2 = MyChildModel.new
puts "mcm2 attributes=" + MyChildModel.defined_attributes.inspect

=end
