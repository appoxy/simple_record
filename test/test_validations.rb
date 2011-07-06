gem 'test-unit'
require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require_relative "test_base"
require "yaml"
require 'aws'
require_relative 'my_model'
require_relative 'my_child_model'
require_relative 'model_with_enc'
require_relative 'models/validated_model'

# Tests for SimpleRecord
#

class TestValidations < TestBase

  #
  #def test_validations
  #  mm = MyModel.new()
  #  puts 'invalid? ' + mm.invalid?.to_s
  #  assert mm.invalid?, "mm is valid. invalid? returned #{mm.invalid?}"
  #  assert mm.errors.size == 1
  #  assert !mm.attr_before_create
  #  assert !mm.valid?
  #  assert mm.save == false, mm.errors.inspect
  #  assert !mm.attr_before_create # should not get called if not valid
  #  assert !mm.attr_after_save
  #  assert !mm.attr_after_create
  #  mm.name = "abcd"
  #  assert mm.valid?, mm.errors.inspect
  #  assert mm.errors.size == 0
  #
  #  mm.save_count = 2
  #  assert mm.invalid?
  #
  #  mm.save_count = nil
  #  assert mm.valid?
  #  assert mm.save, mm.errors.inspect
  #
  #  p mm
  #  assert mm.attr_before_create
  #  assert mm.attr_after_save
  #  assert mm.attr_after_create
  #  assert !mm.attr_after_update
  #
  #  assert mm.valid?, mm.errors.inspect
  #  assert mm.save_count == 1
  #
  #  mm.name = "abc123"
  #  assert mm.save
  #
  #  assert mm.attr_after_update
  #
  #end
  #

  def test_more_validations

    name = 'travis'
    
    puts 'deleted=' + ValidatedModel.delete_all(:conditions=>['name=?', name]).inspect
    sleep 1

    model = ValidatedModel.new
    assert !model.valid?
    assert !model.save
    p model
    model.name = name
    assert model.valid?
    assert model.save
    sleep 1

    model2 = ValidatedModel.new
    model2.name = name
    assert !model.valid?
    assert !model.save
    assert model.errors.size > 0


  end

end
