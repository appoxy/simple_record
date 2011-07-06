require_relative "../../lib/simple_record"
require 'active_model'

class ValidatedModel < MyBaseModel

  has_strings :name

  validates_presence_of :name
  validates_uniqueness_of :name


end
