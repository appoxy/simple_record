require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require File.join(File.dirname(__FILE__), "./test_base")
require "yaml"
require 'aws'
require_relative 'my_model'
require_relative 'my_child_model'
require_relative 'model_with_enc'
require 'active_support/core_ext'

# Tests for SimpleRecord
#

class TestJson < TestBase


    def test_json
        mm = MyModel.new

        mm.name = "whatever"
        mm.age = "1"

        
        jsoned = mm.to_json
        puts 'jsoned=' + jsoned
        unjsoned = JSON.parse jsoned
        puts 'unjsoned=' + unjsoned.inspect
        assert unjsoned.name == "whatever"

        mm.save

        puts 'no trying an array'

        data = {}
        models = []
        data[:models] = models

        models << mm

        jsoned = models.to_json
        puts 'jsoned=' + jsoned
        unjsoned = JSON.parse jsoned
        puts 'unjsoned=' + unjsoned.inspect
        assert unjsoned.size == models.size
        assert unjsoned[0].name == mm.name
        assert unjsoned[0].age == mm.age
        assert unjsoned[0].created.present?
        assert unjsoned[0].id.present?
        assert unjsoned[0].id == mm.id, "unjsoned.id=#{unjsoned[0].id}"

        puts 'array good'

        t = Tester.new
        t2 = Tester.new
        t2.x1 = "i'm number 2"
        t.x1 = 1
        t.x2 = t2
        jsoned = t.to_json

        puts 'jsoned=' + jsoned

        puts 'non simplerecord object good'

        mcm = MyChildModel.new
        mcm.name = "child"
        mcm.my_model = mm
        jsoned = mcm.to_json
        puts 'jsoned=' + jsoned
        unjsoned = JSON.parse jsoned
        puts 'unjsoned=' + unjsoned.inspect
        assert mcm.my_model.id == unjsoned.my_model.id

    end

end

class Tester

    attr_accessor :x1, :x2

end