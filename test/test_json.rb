require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require File.join(File.dirname(__FILE__), "./test_base")
require "yaml"
require 'aws'
require 'my_model'
require 'my_child_model'
require 'model_with_enc'
require 'active_support'

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

        t = Tester.new
        t2 = Tester.new
        t2.x1 = "i'm number 2"
        t.x1 = 1
        t.x2 = t2
        t.to_json
        jsoned = JSON.generate t
        puts 'jsoned=' + jsoned

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