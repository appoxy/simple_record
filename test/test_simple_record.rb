require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'aws'
require 'my_model'
require 'my_child_model'
require 'active_support'

# Tests for SimpleRecord
#

class TestSimpleRecord < Test::Unit::TestCase

    def setup
        @config = YAML::load(File.open(File.expand_path("~/.test-configs/simple_record.yml")))
        #puts 'inspecting config = ' + @config.inspect       

        # Establish AWS connection directly
        @@sdb = Aws::SdbInterface.new(@config['amazon']['access_key'], @config['amazon']['secret_key'], {:connection_mode => :per_request, :protocol => "http", :port => 80})

        SimpleRecord.establish_connection(@config['amazon']['access_key'], @config['amazon']['secret_key'], :connection_mode=>:single)
        SimpleRecord::Base.set_domain_prefix("simplerecord_tests_")
    end

    def teardown
        SimpleRecord.close_connection
    end


    def test_save_get
        mm = MyModel.new
        mm.name = "Travis"
        mm.age = 32
        mm.cool = true
        mm.save

        assert !mm.created.nil?
        assert !mm.updated.nil?
        assert !mm.id.nil?
        assert mm.age == 32
        assert mm.cool = true
        assert mm.name = "Travis"

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
        assert mm2.cool = true
        assert mm2.name = "Travis"
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
        child.save

        child = MyChildModel.find(child.id)
        puts child.my_model_id
        assert child.my_model_id == mm.id
    end

    def test_callbacks


        mm = MyModel.new
        assert !mm.save
        assert mm.errors.count == 1 # name is required

        # test queued callback before_create
        mm.name = "Travis"
        assert mm.save
        # now nickname should be set on before_create
        assert mm.nickname == mm.name

        mm2 = MyModel.find(mm.id)
        assert mm2.nickname = mm.nickname
        assert mm2.name = mm.name


    end

    def test_dirty
        mm = MyModel.new
        mm.name = "Travis"
        mm.age = 32
        mm.cool = true
        mm.save
        id = mm.id
        puts 'id=' + id.to_s
        # Get the object back
        mm2 = MyModel.find(id)
        puts 'got=' + mm2.name + ' and he/she is ' + mm2.age.to_s + ' years old and he/she is cool? ' + mm2.cool.to_s
        assert mm2.id == mm.id
        assert mm2.age == mm.age
        assert mm2.cool == mm.cool

        mm2.name = "Travis 2"
        mm2.save(:dirty=>true)

        # todo: how do we assert this?  perhaps change a value directly in sdb and see that it doesn't get overwritten.
        # or check stats and ensure only 1 attribute was put

        # Test to ensure that if an item is not dirty, sdb doesn't get hit
        puts SimpleRecord.stats.puts.to_s
        SimpleRecord.stats.clear
        mm2.save(:dirty=>true)
        puts SimpleRecord.stats.puts.to_s
        assert SimpleRecord.stats.puts == 0
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
        assert mm.name_was == "Travis"
        assert mm.name_change[0] == "Travis"
        assert mm.name_change[1] == "Jim"

    end

    def test_count

        SimpleRecord.stats.clear

        count = MyModel.find(:count) # select 1
        assert count > 0

        mms = MyModel.find(:all) # select 2
        assert mms.size > 0 # select 3
        assert mms.size == count, "size != count! size=" + mms.size.to_s + " count=" + count.to_s
        assert SimpleRecord.stats.selects == 3, "should have been 3 select, but was actually #{SimpleRecord.stats.selects}" # count should not have been called twice

        count = MyModel.find(:count, :conditions=>["name=?", "Travis"])
        assert count > 0

        mms = MyModel.find(:all, :conditions=>["name=?", "Travis"])
        assert mms.size > 0
        assert mms.size == count

    end

    def test_select
        # just passes through to find
        MyModel.select(:count)
    end

    def test_attributes_correct
        # child should contain child class attributes + parent class attributes

        #MyModel.defined_attributes.each do |a|
        #
        #end
        #MyChildModel.defined_attributes.inspect

    end

    # ensures that it uses next token and what not
    def test_big_result
        i = clear_out_my_models
        num_made = 110
        num_made.times do |i|
            mm = MyModel.create(:name=>"Travis", :age=>i, :cool=>true)
        end
        rs = MyModel.find(:all) # should get 100 at a time
        assert rs.size == num_made
        i = 0
        rs.each do |x|
            #puts 'x=' + x.id
            i+=1
        end
        assert i == num_made
    end

    def clear_out_my_models
        mms = MyModel.find(:all)
        puts 'mms.size=' + mms.size.to_s
        i = 0
        mms.each do |x|
            puts 'deleting=' + i.to_s
            x.delete
            i+=1
        end
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

    # Use to populate db
    def create_my_models(count)
        batch = []
        count.times do |i|
            mm = MyModel.new(:name=>"model_" + i.to_s)
            batch << mm
        end
        MyModel.batch_save batch


    end

    def test_objects_in_constructor
        mm = MyModel.new(:name=>"model1")
        mm.save
        # my_model should be treated differently since it's a belong_to
        mcm = MyChildModel.new(:name=>"johnny", :my_model=>mm)
        mcm.save

        assert mcm.my_model != nil

        mcm = MyChildModel.find(mcm.id)
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

        sleep 2

        # Should have 1 age attribute
        sdb_atts = @@sdb.get_attributes('simplerecord_tests_mymodel', mm.id, 'age')
        assert sdb_atts[:attributes].size == 1, "hmmm, not size 1: " + sdb_atts[:attributes].size.to_s

        mm.age = nil
        mm.save

        # Should be NIL
        assert mm.age == nil

        # Should have NO age attributes
        assert @@sdb.get_attributes('simplerecord_tests_mymodel', mm.id, 'age')[:attributes].size == 0
    end

    def test_null
        puts Time.now.to_i.to_s
        clear_out_my_models

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
        mms = MyModel.find(:all)

        mms2 = MyModel.find(:all, :conditions=>["id in ?"])

    end

    def test_base_attributes
        mm = MyModel.new()
        mm.name = "test name"
        mm.base_string = "in base class"
        mm.save_with_validation!

        mm2 = MyModel.find(mm.id)
        assert mm2.base_string == mm.base_string

        mm2.base_string = "changed base string"
        mm2.save_with_validation!

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
        assert mm

        mm = MyModel.find(:first, :conditions=>["date2 >= ?", 1.minutes.ago])
        puts 'mm=' + mm.inspect
        assert mm

        mm = MyModel.find(:first, :conditions=>["date3 >= ?", 1.minutes.ago])
        puts 'mm=' + mm.inspect
        assert mm
        
    end

    def test_attr_encrypted
        require 'model_with_enc'
        ssn = "123456789"
        password = "my_password"
        ob = ModelWithEnc.new
        ob.name = "my name"
        ob.ssn = ssn
        ob.password = password
        puts "ob before save=" + ob.inspect
        assert ssn == ob.ssn, "#{ssn} != #{ob.ssn} apparently!?"
        assert password == ob.password
        ob.save

        puts "ob after save=" + ob.inspect
        assert ssn == ob.ssn
        assert password == ob.password

        sleep 2

        ob2 = ModelWithEnc.find(ob.id)
        puts 'ob2=' + ob2.inspect
        assert ob2.name = ob.name
        assert ob2.ssn = ob.ssn
        assert ob2.ssn == ssn
        assert ob2.password != password
        assert ob2.password == ob.password

        


    end

end
