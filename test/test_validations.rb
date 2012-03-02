gem 'test-unit'
require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require_relative "test_base"
require "yaml"
require 'aws'
require_relative 'models/my_model'
require_relative 'models/my_child_model'
require_relative 'models/model_with_enc'
require_relative 'models/validated_model'

# Tests for SimpleRecord
#

class TestValidations < TestBase

  def test_aaa1 # run first
    MyModel.delete_domain
    ValidatedModel.delete_domain
    MyModel.create_domain
    ValidatedModel.create_domain
  end

  def test_first_validations
    mm = MyModel.new()
    assert mm.invalid?, "mm is valid. invalid? returned #{mm.invalid?}"
    assert_equal 1, mm.errors.size
    assert !mm.attr_before_create
    assert !mm.valid?
    assert mm.save == false, mm.errors.inspect
    assert !mm.attr_before_create # should not get called if not valid
    assert !mm.attr_after_save
    assert !mm.attr_after_create
    mm.name = "abcd"
    assert mm.valid?, mm.errors.inspect
    assert_equal 0, mm.errors.size

    mm.save_count = 2
    assert mm.invalid?

    mm.save_count = nil
    assert mm.valid?
    assert mm.save, mm.errors.inspect

    assert mm.attr_before_create
    assert mm.attr_after_save
    assert mm.attr_after_create
    assert !mm.attr_after_update

    assert mm.valid?, mm.errors.inspect
    assert_equal 1, mm.save_count

    mm.name = "abc123"
    assert mm.save

    assert mm.attr_after_update
  end

  def test_more_validations

    name = 'abcd'
    
    model = ValidatedModel.new
    assert !model.valid?
    assert !model.save
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

  def test_zzz9 # run last
    MyModel.delete_domain
    ValidatedModel.delete_domain
  end
end
