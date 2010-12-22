require 'test/unit'
require_relative "../lib/simple_record"
require_relative "test_helpers"
require_relative "test_base"
require "yaml"
require 'aws'
require_relative 'my_model'
require_relative 'my_child_model'
require_relative 'model_with_enc'

# Tests for SimpleRecord
#

class TestLobs < TestBase


    def test_clobs
        mm = MyModel.new

        puts mm.clob1.inspect
        assert mm.clob1.nil?

        mm.name  = "whatever"
        mm.age   = "1"
        mm.clob1 = "0" * 2000
        assert SimpleRecord.stats.s3_puts == 0
        puts mm.inspect
        mm.save

        assert SimpleRecord.stats.s3_puts == 1
        sleep 2

        mm.clob1 = "1" * 2000
        mm.clob2 = "2" * 2000
        mm.save
        assert SimpleRecord.stats.s3_puts == 3

        mm2 = MyModel.find(mm.id)
        assert mm.id == mm2.id
        puts 'mm.clob1=' + mm.clob1.to_s
        puts 'mm2.clob1=' + mm2.clob1.to_s
        assert mm.clob1 == mm2.clob1
        assert SimpleRecord.stats.s3_puts == 3, "puts is #{SimpleRecord.stats.s3_puts}"
        assert SimpleRecord.stats.s3_gets == 1, "gets is #{SimpleRecord.stats.s3_gets}"
        mm2.clob1 # make sure it doesn't do another get
        assert SimpleRecord.stats.s3_gets == 1

        assert mm.clob2 == mm2.clob2
        assert SimpleRecord.stats.s3_gets == 2

        mm2.save

        # shouldn't save twice if not dirty
        assert SimpleRecord.stats.s3_puts == 3

        mm2.delete

        assert_equal 2, SimpleRecord.stats.s3_deletes

        e = assert_raise(Aws::AwsError) do
            sclob = SimpleRecord.s3.bucket(mm2.s3_bucket_name2).get(mm2.s3_lob_id("clob1"))
        end
        assert_match(/NoSuchKey/, e.message)
        e = assert_raise(Aws::AwsError) do
            sclob = SimpleRecord.s3.bucket(mm2.s3_bucket_name2).get(mm2.s3_lob_id("clob2"))
        end
        assert_match(/NoSuchKey/, e.message)


    end

    def test_single_clob
        mm = SingleClobClass.new

        puts mm.clob1.inspect
        assert mm.clob1.nil?

        mm.name  = "whatever"
        mm.clob1 = "0" * 2000
        mm.clob2 = "2" * 2000
        assert SimpleRecord.stats.s3_puts == 0
        puts mm.inspect
        mm.save

        assert SimpleRecord.stats.s3_puts == 1

        sleep 2

        mm2 = SingleClobClass.find(mm.id)
        assert mm.id == mm2.id
        puts 'mm.clob1=' + mm.clob1.to_s
        puts 'mm2.clob1=' + mm2.clob1.to_s
        assert_equal mm.clob1, mm2.clob1
        assert SimpleRecord.stats.s3_puts == 1, "puts is #{SimpleRecord.stats.s3_puts}"
        assert SimpleRecord.stats.s3_gets == 1, "gets is #{SimpleRecord.stats.s3_gets}"
        mm2.clob1 # make sure it doesn't do another get
        assert SimpleRecord.stats.s3_gets == 1

        assert mm.clob2 == mm2.clob2
        assert SimpleRecord.stats.s3_gets == 1

        mm2.save

        # shouldn't save twice if not dirty
        assert SimpleRecord.stats.s3_puts == 1

        mm2.delete

        assert SimpleRecord.stats.s3_deletes == 1

        e = assert_raise(Aws::AwsError) do
            sclob = SimpleRecord.s3.bucket(mm2.s3_bucket_name2).get(mm2.single_clob_id)
        end
        assert_match(/NoSuchKey/, e.message)

    end

end
