
require "yaml"
require 'aws'

require_relative "../lib/simple_record"
require_relative 'my_model'
require_relative 'my_child_model'

x = 0
puts SimpleRecord::Translations.pad_and_offset(x)

x = 1
puts SimpleRecord::Translations.pad_and_offset(x)

x = "09223372036854775838"
puts SimpleRecord::Translations.un_offset_int(x)
