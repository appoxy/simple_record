require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require_relative "test_base"
require "yaml"
require 'aws'
require_relative 'my_model'
require_relative 'my_child_model'
require_relative 'model_with_enc'

# Tests for SimpleRecord
#

class TestSimpleRecord < TestBase

  def test_validations
    mm = MyModel.new()
    puts 'invalid? ' + mm.invalid?.to_s
    assert mm.invalid?, "mm is valid. invalid? returned #{mm.invalid?}"
    assert mm.errors.size == 1
    assert !mm.attr_before_create
    assert !mm.valid?
    assert mm.save == false, mm.errors.inspect
    assert mm.attr_before_create
    assert !mm.attr_after_save
    assert !mm.attr_after_create
    mm.name = "abcd"
    assert mm.valid?, mm.errors.inspect
    assert mm.errors.size == 0

    mm.save_count = 2
    assert mm.invalid?

    mm.save_count = nil
    assert mm.valid?
    assert mm.save, mm.errors.inspect

    p mm
    assert mm.attr_after_save
    assert mm.attr_after_create

    assert mm.valid?, mm.errors.inspect
    assert mm.save_count == 1
  end
end
