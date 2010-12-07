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


    def test_save_get
        mm = MyModel.new
        mm.name = "Travis"
        mm.age = 32
        mm.cool = true
        mm.save
        sleep 1

        assert !mm.created.nil?
        assert !mm.updated.nil?
        assert !mm.id.nil?
        assert mm.age == 32
        assert mm.cool == true
        assert mm.name == "Travis"

        id = mm.id
        puts 'id=' + id.to_s
        # Get the object back
        mm2 = MyModel.find(id)
        #puts 'got=' + mm2.name + ' and he/she is ' + mm2.age.to_s + ' years old and he/she is cool? ' + mm2.cool.to_s
        #puts mm2.cool.class.name
        assert mm2.id == mm.id
        assert mm2.age == mm.age
        assert mm2.cool == mm.cool
        assert mm2.age == 32
        assert mm2.cool == true
        assert mm2.name == "Travis"
        assert mm2.created.is_a? DateTime

        # test nilification
        mm2.age = nil
        mm2.save
        puts mm2.errors.inspect
        sleep 1
        mm2 = MyModel.find(id)
        puts mm2.inspect
        assert mm2.age.nil?, "doh, age is " + mm2.age.inspect
    end


    def test_updates
        mm = MyModel.new
        mm.name = "Travis"
        mm.age = 32
        mm.cool = true
        mm.s1 = "Initial value"
        mm.save
        id = mm.id
        sleep 1

        mm = MyModel.find(id)
        mm.name = "Travis2"
        mm.age = 10
        mm.cool = false
        mm.s1 = "" # test blank string

        puts 'mm=' + mm.inspect
        mm.save
        sleep 1

        puts 'mm2=' + mm.inspect

        assert mm.s1 == "", "mm.s1 is not empty string, it is " + mm.s1.inspect

        mm = MyModel.find(id)
        assert mm.name == "Travis2"
        assert mm.age == 10
        assert mm.cool == false
        assert mm.s1 == "", "mm.s1 is not empty string, it is #{mm.s1.inspect}"

    end

    def test_funky_values
        mm = MyModel.new(:name=>"Funky")
        mm.s1 = "other/2009-11-10/04/84.eml" # reported here: http://groups.google.com/group/simple-record/browse_thread/thread/3659e82491d03a2c?hl=en
        assert mm.save
        assert mm.errors.size == 0

        mm2 = MyModel.find(mm.id)
        puts 'mm2=' + mm2.inspect

    end


    def test_create
        mm = MyModel.create(:name=>"Travis", :age=>32, :cool=>true)
        puts 'mm=' + mm.inspect
        assert !mm.id.nil?
    end

    def test_bad_query
        assert_raise Aws::AwsError do
            mm2 = MyModel.find(:all, :conditions=>["name =4?", "1"])
        end
    end

    def test_batch_save
        items = []
        mm = MyModel.new
        mm.name = "Travis"
        mm.age = 32
        mm.cool = true
        items << mm
        mm = MyModel.new
        mm.name = "Tritt"
        mm.age = 44
        mm.cool = false
        items << mm
        MyModel.batch_save(items)
        sleep 2
        items.each do |item|
            puts 'id=' + item.id
            new_item = MyModel.find(item.id)
            #puts 'new=' + new_item.inspect
            assert item.id == new_item.id
            assert item.name == new_item.name
            assert item.cool == new_item.cool
        end
    end

    # Testing getting the association ID without materializing the obejct
    def test_get_belongs_to_id
        mm = MyModel.new
        mm.name = "Parent"
        mm.age = 55
        mm.cool = true
        mm.save

        child = MyChildModel.new
        child.name = "Child"
        child.my_model = mm
        puts 'c1=' + child.inspect
        puts 'mmid1=' + child.my_model_id.to_s
        assert child.my_model_id == mm.id
        child.save
        puts 'mmid2=' + child.my_model_id.to_s

        puts "child=" + child.inspect
        sleep 1

        child = MyChildModel.find(child.id)
        puts "child find=" + child.inspect
        puts "child.my_model_id = " + child.my_model_id.to_s
        assert !child.my_model_id.nil?
        assert !child.my_model.nil?
        assert child.my_model_id == mm.id
    end

    def test_callbacks


        mm = MyModel.new
        assert !mm.save
        assert mm.errors.count == 1 # name is required

        # test queued callback before_create
        mm.name = "Travis"
        assert mm.save
        sleep 1
        # now nickname should be set on before_create
        assert mm.nickname == mm.name

        mm2 = MyModel.find(mm.id)
        assert_equal mm2.nickname, mm.nickname
        assert_equal mm2.name, mm.name


    end

    def test_dirty
        mm = MyModel.new
        mm.name = "Travis"
        mm.age = 32
        mm.cool = true
        mm.save
        id = mm.id
        puts 'id=' + id.to_s
        sleep 1
        # Get the object back
        mm2 = MyModel.find(id)
        puts 'mm2=' + mm2.inspect
        puts 'got=' + mm2.name.to_s + ' and he/she is ' + mm2.age.to_s + ' years old and he/she is cool? ' + mm2.cool.to_s
        assert mm2.id == mm.id
        assert mm2.age == mm.age
        assert mm2.cool == mm.cool

        mm2.name = "Travis 2"
        mm2.save(:dirty=>true)

        # todo: how do we assert this?  perhaps change a value directly in sdb and see that it doesn't get overwritten.
        # or check stats and ensure only 1 attribute was put

        # Test to ensure that if an item is not dirty, sdb doesn't get hit
        puts SimpleRecord.stats.saves.to_s
        SimpleRecord.stats.clear
        mm2.save(:dirty=>true)
        puts SimpleRecord.stats.saves.to_s
        assert SimpleRecord.stats.saves == 0

        mmc = MyChildModel.new
        mmc.my_model = mm
        mmc.x = mm
        mmc.save

        sleep 1

        mmc2 = MyChildModel.find(mmc.id)
        assert mmc2.my_model_id == mmc.my_model_id, "mm2.my_model_id=#{mmc2.my_model_id} mmc.my_model_id=#{mmc.my_model_id}"
        puts 'setting my_model to nil'
        mmc2.my_model = nil
        mmc2.x = nil
        puts 'saving my_model to nil'
        SimpleRecord.stats.clear
        assert mmc2.save(:dirty=>true)
        assert SimpleRecord.stats.saves == 1, "saves is #{SimpleRecord.stats.saves}" # 1 put only for updated, should have a count of attributes saved in stats
        assert SimpleRecord.stats.deletes == 1, "deletes is #{SimpleRecord.stats.deletes}"
        assert mmc2.id == mmc.id
        assert mmc2.my_model_id == nil
        assert mmc2.my_model == nil, "my_model not nil? #{mmc2.my_model.inspect}"

        sleep 1

        mmc3 = MyChildModel.find(mmc.id)
        puts "mmc3 1 =" + mmc3.inspect
        assert mmc3.my_model_id == nil, "my_model_id not nil? #{mmc3.my_model_id.inspect}"
        assert mmc3.my_model == nil

        mm3 = MyModel.new(:name=>"test")
        assert mm3.save
        sleep 1

        mmc3.my_model = mm3
        assert mmc3.my_model_changed?
        assert mmc3.save(:dirty=>true)
        assert mmc3.my_model_id == mm3.id
        assert mmc3.my_model.id == mm3.id

        sleep 1
        mmc3 = MyChildModel.find(mmc3.id)
        puts "mmc3=" + mmc3.inspect
        assert mmc3.my_model_id == mm3.id, "my_model_id=#{mmc3.my_model_id.inspect} mm3.id=#{mm3.id.inspect}"
        assert mmc3.my_model.id == mm3.id

        mmc3 = MyChildModel.find(mmc3.id)
        mmc3.my_model_id = mm2.id
        assert mmc3.my_model_id == mm2.id
        assert mmc3.changed?
        assert mmc3.my_model_changed?
        assert mmc3.my_model.id == mm2.id

    end

    # http://api.rubyonrails.org/classes/ActiveRecord/Dirty.html#M002136
    def test_changed
        mm = MyModel.new
        mm.name = "Travis"
        mm.age = 32
        mm.cool = true
        mm.save

        puts 'changed?=' + mm.changed?.to_s
        assert !mm.changed?
        assert mm.changed.size == 0
        assert mm.changes.size == 0
        assert !mm.name_changed?

        mm.name = "Jim"
        assert mm.changed?
        assert mm.changed.size == 1
        assert mm.changed[0] == "name"

        assert mm.changes.size == 1
        puts 'CHANGES=' + mm.changes.inspect
        assert mm.changes["name"][0] == "Travis"
        assert mm.changes["name"][1] == "Jim"

        assert mm.name_changed?
        assert mm.name_was == "Travis", "was #{mm.name_was}"
        assert mm.name_change[0] == "Travis"
        assert mm.name_change[1] == "Jim"

    end

    def test_count

        SimpleRecord.stats.clear

        count = MyModel.find(:count) # select 1
        assert count > 0

        mms = MyModel.find(:all) # select 2
        puts 'mms=' + mms.inspect
        assert mms.size > 0 # select 3
        puts 'mms=' + mms.inspect
        assert mms.size == count, "size != count! size=" + mms.size.to_s + " count=" + count.to_s
        assert SimpleRecord.stats.selects == 3, "should have been 3 select, but was actually #{SimpleRecord.stats.selects}" # count should not have been called twice

        count = MyModel.find(:count, :conditions=>["name=?", "Travis"])
        assert count > 0

        mms = MyModel.find(:all, :conditions=>["name=?", "Travis"])
        assert mms.size > 0
        assert mms.size == count

    end

    def test_attributes_correct
        # child should contain child class attributes + parent class attributes

        #MyModel.defined_attributes.each do |a|
        #
        #end
        #MyChildModel.defined_attributes.inspect

    end

    def test_results_array
        mms = MyModel.find(:all) # select 2
        assert !mms.first.nil?
        assert !mms.last.nil?
        assert !mms.empty?
        assert mms.include?(mms[0])

        assert mms[2, 2].size == 2
        assert mms[2..5].size == 4
        assert mms[2...5].size == 3

    end

    def test_random_index
        create_my_models(120)
        mms = MyModel.find(:all)
        o = mms[85]
        puts 'o=' + o.inspect
        assert !o.nil?
        o = mms[111]
        puts 'o=' + o.inspect
        assert !o.nil?
    end

    def test_objects_in_constructor
        mm = MyModel.new(:name=>"model1")
        mm.save
        # my_model should be treated differently since it's a belong_to
        mcm = MyChildModel.new(:name=>"johnny", :my_model=>mm)
        mcm.save
        sleep 1

        assert mcm.my_model != nil

        mcm = MyChildModel.find(mcm.id)
        puts 'mcm=' + mcm.inspect
        assert mcm.my_model != nil

    end

    def test_validations
        mm = MyModel.new()
        assert mm.invalid?
        assert mm.errors.size == 1
        mm.name = "abcd"
        assert mm.valid?
        assert mm.errors.size == 0

        mm.save_count = 2
        assert mm.invalid?

        mm.save_count = nil

        assert mm.save, mm.errors.inspect

        assert mm.valid?, mm.errors.inspect
        assert mm.save_count == 1
    end


    def test_nil_attr_deletion
        mm = MyModel.new
        mm.name = "Chad"
        mm.age = 30
        mm.cool = false
        mm.save

        sleep 1

        # Should have 1 age attribute
        sdb_atts = @@sdb.get_attributes('simplerecord_tests_my_models', mm.id, 'age')
        puts 'sdb_atts=' + sdb_atts.inspect
        assert sdb_atts[:attributes].size == 1, "hmmm, not size 1: " + sdb_atts[:attributes].size.to_s

        mm.age = nil
        mm.save
        sleep 1

        # Should be NIL
        assert mm.age == nil, "age is #{mm.age}"

        # Should have NO age attributes
        assert @@sdb.get_attributes('simplerecord_tests_my_models', mm.id, 'age')[:attributes].size == 0
    end

    def test_null
        puts Time.now.to_i.to_s
        TestHelpers.clear_out_my_models

        mm = MyModel.new(:name=>"birthay is null")
        mm.save
        mm2 = MyModel.new(:name=>"birthday is not null")
        mm2.birthday = Time.now
        mm2.save
        sleep 2
        mms = MyModel.find(:all, :conditions=>["birthday is null"])
        mms.each do |m|
            puts m.inspect
        end
        assert mms.size == 1
        assert mms[0].id = mm.id
        mms = MyModel.find(:all, :conditions=>["birthday is not null"])
        mms.each do |m|
            puts m.inspect
        end
        assert mms.size == 1
        assert mms[0].id = mm2.id

    end

    # Test to add support for IN
    def test_in_clause
#        mms = MyModel.find(:all)

#        mms2 = MyModel.find(:all, :conditions=>["id in ?"])

    end

    def test_base_attributes
        mm = MyModel.new()
        mm.name = "test name"
        mm.base_string = "in base class"
        mm.save_with_validation!
        sleep 1

        mm2 = MyModel.find(mm.id)
        assert mm2.base_string == mm.base_string

        mm2.base_string = "changed base string"
        mm2.save_with_validation!
        sleep 1

        mm3 = MyModel.find(mm2.id)
        assert mm3.base_string == mm2.base_string
        puts mm3.inspect


    end

    def test_dates
        mm = MyModel.new()
        mm.name = "test name"
        mm.date1 = Date.today
        mm.date2 = Time.now
        mm.date3 = DateTime.now
        mm.save

        sleep 1

        mm = MyModel.find(:first, :conditions=>["date1 >= ?", 1.days.ago.to_date])
        puts 'mm=' + mm.inspect
        assert mm.is_a? MyModel

        mm = MyModel.find(:first, :conditions=>["date2 >= ?", 1.minutes.ago])
        puts 'mm=' + mm.inspect
        assert mm.is_a? MyModel

        mm = MyModel.find(:first, :conditions=>["date3 >= ?", 1.minutes.ago])
        puts 'mm=' + mm.inspect
        assert mm.is_a? MyModel

    end

    def test_attr_encrypted
        require_relative 'model_with_enc'
        ssn = "123456789"
        password = "my_password"

        ob = ModelWithEnc.new
        ob.name = "my name"
        ob.ssn = ssn
        ob.password = password
        puts "ob before save=" + ob.inspect
        assert ssn == ob.ssn, "#{ssn} != #{ob.ssn} apparently!?"
        puts "#{ob.password.class.name} ob.password=#{ob.password} password=#{password}"
        assert password != ob.password # we know this doesn't work right
        assert ob.password == password, "#{ob.password.class.name} ob.password=#{ob.password} password=#{password}"
        ob.save

        # try also with constructor, just to be safe
        ob = ModelWithEnc.create(:ssn=>ssn, :name=>"my name", :password=>password)
        assert ssn == ob.ssn, "#{ssn} != #{ob.ssn} apparently!?"
        puts "#{ob.password.class.name} ob.password=#{ob.password} password=#{password}"
        assert password != ob.password # we know this doesn't work right
        assert ob.password == password, "#{ob.password.class.name} ob.password=#{ob.password} password=#{password}"
        puts "ob after save=" + ob.inspect
        assert ssn == ob.ssn
        assert ob.password == password, "#{ob.password.class.name} ob.password=#{ob.password} password=#{password}"

        sleep 2

        ob2 = ModelWithEnc.find(ob.id)
        puts 'ob2=' + ob2.inspect
        assert ob2.name == ob.name, "#{ob2.name} vs #{ob.name}"
        assert ob2.ssn == ob.ssn, "#{ob2.ssn} vs #{ob.ssn}"
        assert ob2.ssn == ssn, "#{ob2.ssn} vs #{ssn}"
        assert ob2.password == password, "#{ob2.password} vs #{password}"
        assert ob2.attributes["password"] != password
        assert ob2.password == ob.password, "#{ob2.password} vs #{ob.password}"

    end

    def test_non_persistent_attributes
        mm = MyModel.new({:some_np_att=>"word"})
        mm = MyModel.new({"some_other_np_att"=>"up"})

    end

    def test_atts_using_strings_and_symbols
        mm = MyModel.new({:name=>"myname"})
        mm2 = MyModel.new({"name"=>"myname"})
        assert_equal(mm.name, mm2.name)

        mm.save
        mm2.save
        sleep 1

        mm = MyModel.find(mm.id)
        mm2 = MyModel.find(mm2.id)
        assert_equal mm.name, mm2.name
    end

    def test_constructor_using_belongs_to_ids
        mm = MyModel.new({:name=>"myname"})
        mm.save
        sleep 1

        mm2 = MyChildModel.new({"name"=>"myname2", :my_model_id=>mm.id})
        puts 'mm2=' + mm2.inspect
        assert_equal mm.id, mm2.my_model_id, "#{mm.id} != #{mm2.my_model_id}"
        mm3 = mm2.my_model
        puts 'mm3=' + mm3.inspect
        assert_equal mm.name, mm3.name

        mm3 = MyChildModel.create(:my_model_id=>mm.id, :name=>"myname3")

        sleep 2
        mm4 = MyChildModel.find(mm3.id)
        assert_equal mm4.my_model_id, mm.id
        assert !mm4.my_model.nil?

    end

    def test_update_attributes
        mm = MyModel.new({:name=>"myname"})
        mm.save

        now = Time.now
        mm.update_attributes(:name=>"name2", :age=>21, "date2"=>now)
        assert mm.name == "name2", "Name is #{mm.name}"
        assert mm.age == 21
#        assert mm.date2.to_time.utc == now.utc, "#{mm.date2.class.name} #{mm.date2.to_time.inspect} != #{now.inspect}"
        sleep 1

        mm = MyModel.find(mm.id)
        assert mm.name == "name2", "Name is #{mm.name}"
        assert mm.age == 21, "Age is not 21, it is #{mm.age}"
#        assert mm.date2 == now, "Date is not correct, it is #{mm.date2}"
    end

    def test_explicit_class_name
        mm = MyModel.new({:name=>"myname"})
        mm.save
        sleep 1

        mm2 = MyChildModel.new({"name"=>"myname2"})
        mm2.x = mm
        assert mm2.x.id == mm.id
        mm2.save
        sleep 1

        mm3 = MyChildModel.find(mm2.id)
        puts "mm3.x=" + mm3.x.inspect
        assert mm3.x.id == mm.id
    end

    def test_storage_format

        mm = MyModel.new({:name=>"myname"})
        mm.date1 = Time.now
        mm.date2 = DateTime.now
        mm.save
        sleep 1

        raw = @@sdb.get_attributes(MyModel.domain, mm.id)
        puts "raw=" + raw.inspect
        assert raw[:attributes]["updated"][0].size == "2010-01-06T16:04:23".size
        assert raw[:attributes]["date1"][0].size == "2010-01-06T16:04:23".size
        assert raw[:attributes]["date2"][0].size == "2010-01-06T16:04:23".size

    end

    def test_empty_initialize
        mm = MyModel.new

        mme = ModelWithEnc.new
        mme = ModelWithEnc.new(:ssn=>"", :password=>"") # this caused encryptor errors
        mme = ModelWithEnc.new(:ssn=>nil, :password=>nil)
    end

    def test_string_ints
        mm = MyModel.new
        mm.name = "whatever"
        mm.age = "1"
        puts mm.inspect

        mm2 = MyModel.new
        mm2.name = "whatever2"
        mm2.age = 1
        params = {:name=>"scooby", :age=>"123"}
        mm3 = MyModel.new(params)


        assert mm.age == 1, "mm.age=#{mm.age}"
        assert mm2.age == 1
        assert mm3.age == 123

        mm.save!
        mm2.save!
        mm3.save!
        sleep 1

        assert mm.age == 1
        assert mm2.age == 1
        assert mm3.age == 123

        mmf1 = MyModel.find(mm.id)
        mmf2 = MyModel.find(mm2.id)
        mmf3 = MyModel.find(mm3.id)

        assert mmf1.age == 1
        assert mmf2.age == 1
        assert mmf3.age == 123

        mmf1.update_attributes({:age=>"456"})

        mmf1.age == 456

    end

    def test_box_usage
        mm = MyModel.new
        mm.name = "whatever"
        mm.age = "1"
        mm.save
        sleep 1

        mms = MyModel.all

        assert mms.box_usage && mms.box_usage > 0
        assert mms.request_id

    end

    def test_multi_value_attributes

        val = ['a', 'b', 'c']
        val2 = [1, 2, 3]

        mm = MyModel.new
        mm.name = val
        mm.age = val2
        assert_equal val, mm.name
        assert_equal val2, mm.age
        mm.save

        sleep 1
        mm = MyModel.find(mm.id)
        # Values are not returned in order
        assert_equal val, mm.name.sort
        assert_equal val2, mm.age.sort




    end

end
