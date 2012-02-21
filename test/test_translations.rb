gem 'test-unit'
require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require_relative "test_base"
require "yaml"
require 'aws'
require_relative 'models/my_translation'

# Tests for simple_record/translations.rb
#

class TestTranslations < TestBase

  def test_aaa1 # run first
    MyTranslation.delete_domain
    MyTranslation.create_domain
  end

  def test_first_validations
    mt = MyTranslation.new()
    mt.name = "Marvin"
    mt.stage_name = "Kelly"
    mt.age = 29
    mt.singer = true
    mt.birthday = Date.new(1990,03,15)
    mt.weight = 70
    mt.height = 150
    mt.save
     
    mt2 = MyTranslation.find(mt.id, :consistent_read => true)
    assert_kind_of String, mt2.name
    assert_kind_of String, mt2.stage_name
    assert_kind_of Integer, mt2.age
    assert_kind_of Date, mt2.birthday
    assert_kind_of Float, mt2.weight
    assert_kind_of Float, mt2.height 
    # sadly, there is no bool type in Ruby
    assert (mt.singer.is_a?(TrueClass) || mt.singer.is_a?(FalseClass))
    assert_equal mt.name, mt2.name
    assert_equal mt.stage_name, mt2.stage_name
    assert_equal mt.age, mt2.age
    assert_equal mt.singer, mt2.singer
    assert_equal mt.birthday, mt2.birthday
    assert_equal mt.weight, mt2.weight
    assert_equal mt.height, mt2.height
  end

  def test_zzz9 # run last
    MyTranslation.delete_domain
  end
end
