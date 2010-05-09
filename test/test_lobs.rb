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

class TestLobs < TestBase


    def test_blobs
        mm = MyModel.new

        puts mm.clob1.inspect
        assert mm.clob1.nil?
        
        mm.name = "whatever"
        mm.age = "1"
        mm.clob1 = "0" * 2000
        assert SimpleRecord.stats.s3_puts == 0
        puts mm.inspect
        mm.save

        sleep 2

        mm2 = MyModel.find(mm.id)
        assert mm.id == mm2.id
        puts 'mm.clob1=' + mm.clob1.to_s
        puts 'mm2.clob1=' + mm2.clob1.to_s
        assert mm.clob1 == mm2.clob1
        assert SimpleRecord.stats.s3_puts == 1, "puts is #{SimpleRecord.stats.s3_puts}"
        assert SimpleRecord.stats.s3_gets == 1, "gets is #{SimpleRecord.stats.s3_gets}"
        mm2.clob1 # make sure it doesn't do another get
        assert SimpleRecord.stats.s3_gets == 1

        mm2.save

        # shouldn't save twice if not dirty
         assert SimpleRecord.stats.s3_puts == 1

    end

end
