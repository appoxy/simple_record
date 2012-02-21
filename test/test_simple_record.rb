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
require_relative 'models/my_simple_model'

# Tests for SimpleRecord
#

class TestSimpleRecord < TestBase
  def test_aaa_first_at_bat
    MyModel.delete_domain
    MyChildModel.delete_domain
    ModelWithEnc.delete_domain
    MyModel.create_domain
    MyChildModel.create_domain
    ModelWithEnc.create_domain
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
    assert_equal mm.age, 32
    assert_equal mm.cool, true
    assert_equal mm.name, "Travis"

    id = mm.id
    # Get the object back
    mm2 = MyModel.find(id,:consistent_read=>true)
    assert_equal mm2.id, mm.id
    assert_equal mm2.age, mm.age
    assert_equal mm2.cool, mm.cool
    assert_equal mm2.age, 32
    assert_equal mm2.cool, true
    assert_equal mm2.name, "Travis"
    assert mm2.created.is_a? DateTime

    # test nilification
    mm2.age = nil
    mm2.save
    sleep(2) # not sure why this might work... not respecting consistent_read?
    mm3 = MyModel.find(id,:consistent_read=>true)
    assert mm2.age.nil?, "doh, age should be nil, but it's " + mm2.age.inspect
  end

  def test_custom_id
    custom_id = "id-travis"
    mm = MyModel.new
    mm.id = custom_id
    mm.name = "Marvin"
    mm.age = 32
    mm.cool = true
    mm.save
    mm2 = MyModel.find(custom_id,:consistent_read=>true)
    assert_equal mm2.id, mm.id
  end

  def test_updates
    mm = MyModel.new
    mm.name = "Angela"
    mm.age = 32
    mm.cool = true
    mm.s1 = "Initial value"
    mm.save
    id = mm.id

    mm = MyModel.find(id, :consistent_read=>true)
    mm.name = "Angela2"
    mm.age = 10
    mm.cool = false
    mm.s1 = "" # test blank string

    mm.save

    assert_equal mm.s1, ""

    mm = MyModel.find(id, :consistent_read=>true)
    assert_equal mm.name, "Angela2"
    assert_equal mm.age, 10
    assert_equal mm.cool, false
    assert_equal mm.s1, ""

  end

  def test_funky_values
    mm = MyModel.new(:name=>"Funky")
    mm.s1 = "other/2009-11-10/04/84.eml" # reported here: http://groups.google.com/group/simple-record/browse_thread/thread/3659e82491d03a2c?hl=en
    assert mm.save
    assert_equal mm.errors.size, 0

    mm2 = MyModel.find(mm.id,:consistent_read=>true)

  end


  def test_create
    mm = MyModel.create(:name=>"Craven", :age=>32, :cool=>true)
    assert !mm.id.nil?
  end

  def test_bad_query
    assert_raise Aws::AwsError do
      mm2 = MyModel.find(:all, :conditions=>["name =4?", "1"],:consistent_read=>true)
    end
  end

  def test_batch_save
    items = []
    mm = MyModel.new
    mm.name = "Beavis"
    mm.age = 32
    mm.cool = true
    items << mm
    mm = MyModel.new
    mm.name = "Butthead"
    mm.age = 44
    mm.cool = false
    items << mm
    MyModel.batch_save(items)
    items.each do |item|
      new_item = MyModel.find(item.id,:consistent_read=>true)
      assert_equal item.id, new_item.id
      assert_equal item.name, new_item.name
      assert_equal item.cool, new_item.cool
    end
  end

  # Testing getting the association ID without materializing the obejct
  def test_get_belongs_to_id
    mm = MyModel.new
    mm.name = "Parent"
    mm.age = 55
    mm.cool = true
    mm.save
    sleep(1) #needed because child.my_model below does not have :consistent_read set

    child = MyChildModel.new
    child.name = "Child"
    child.my_model = mm
    assert_equal child.my_model_id, mm.id
    child.save

    child = MyChildModel.find(child.id,:consistent_read=>true)
    assert !child.my_model_id.nil?
    assert !child.my_model.nil?
    assert_equal child.my_model_id, mm.id
  end

  def test_callbacks


    mm = MyModel.new
    assert !mm.save
    assert_equal mm.errors.count, 1 # name is required

    # test queued callback before_create
    mm.name = "Oresund"
    assert mm.save
    # now nickname should be set on before_create
    assert_equal mm.nickname, mm.name

    mm2 = MyModel.find(mm.id,:consistent_read=>true)
    assert_equal mm2.nickname, mm.nickname
    assert_equal mm2.name, mm.name


  end

  def test_dirty
    mm = MyModel.new
    mm.name = "Persephone"
    mm.age = 32
    mm.cool = true
    mm.save
    id = mm.id
    # Get the object back
    mm2 = MyModel.find(id,:consistent_read=>true)
    assert_equal mm2.id, mm.id
    assert_equal mm2.age, mm.age
    assert_equal mm2.cool, mm.cool

    mm2.name = "Persephone 2"
    mm2.save(:dirty=>true)

    # todo: how do we assert this?  perhaps change a value directly in sdb and see that it doesn't get overwritten.
    # or check stats and ensure only 1 attribute was put

    # Test to ensure that if an item is not dirty, sdb doesn't get hit
    SimpleRecord.stats.clear
    mm2.save(:dirty=>true)
    assert_equal 0, SimpleRecord.stats.saves

    sleep(1) #needed because mmc.my_model below does not have :consistent_read set
    mmc = MyChildModel.new
    mmc.my_model = mm
    mmc.x = mm
    mmc.save


    mmc2 = MyChildModel.find(mmc.id,:consistent_read=>true)
    assert_equal mmc2.my_model_id, mmc.my_model_id
    mmc2.my_model = nil
    mmc2.x = nil
    SimpleRecord.stats.clear
    assert mmc2.save(:dirty=>true)
    assert_equal SimpleRecord.stats.saves, 1
    assert_equal SimpleRecord.stats.deletes, 1
    assert_equal mmc2.id, mmc.id
    assert_equal mmc2.my_model_id, nil
    assert_equal mmc2.my_model, nil

    mmc3 = MyChildModel.find(mmc.id,:consistent_read=>true)
    assert_equal mmc3.my_model_id, nil
    assert_equal mmc3.my_model, nil

    mm3 = MyModel.new(:name=>"test")
    assert mm3.save
    sleep(1) #needed because mmc3.my_model below does not have :consistent_read set

    mmc3.my_model = mm3
    assert mmc3.my_model_changed?
    assert mmc3.save(:dirty=>true)
    assert_equal mmc3.my_model_id, mm3.id
    assert_equal mmc3.my_model.id, mm3.id

    mmc3 = MyChildModel.find(mmc3.id,:consistent_read=>true)
    assert_equal mmc3.my_model_id, mm3.id
    assert_equal mmc3.my_model.id, mm3.id

    mmc3 = MyChildModel.find(mmc3.id,:consistent_read=>true)
    mmc3.my_model_id = mm2.id
    assert_equal mmc3.my_model_id, mm2.id
    assert mmc3.changed?
    assert mmc3.my_model_changed?
    assert_equal mmc3.my_model.id, mm2.id

  end

  # http://api.rubyonrails.org/classes/ActiveRecord/Dirty.html#M002136
  def test_changed
    mm = MySimpleModel.new
    mm.name = "Horace"
    mm.age = 32
    mm.cool = true
    mm.save

    assert !mm.changed?
    assert_equal mm.changed.size, 0
    assert_equal mm.changes.size, 0
    assert !mm.name_changed?

    mm.name = "Jim"
    assert mm.changed?
    assert_equal mm.changed.size, 1
    assert_equal mm.changed[0], "name"

    assert_equal mm.changes.size, 1
    assert_equal mm.changes["name"][0], "Horace"
    assert_equal mm.changes["name"][1], "Jim"

    assert mm.name_changed?
    assert_equal mm.name_was, "Horace"
    assert_equal mm.name_change[0], "Horace"
    assert_equal mm.name_change[1], "Jim"

  end

  def test_count

    SimpleRecord.stats.clear

    count = MyModel.find(:count,:consistent_read=>true) # select 1
    assert count > 0

    mms = MyModel.find(:all,:consistent_read=>true) # select 2
    assert mms.size > 0 # still select 2
    assert_equal mms.size, count
    assert_equal 2, SimpleRecord.stats.selects

    sleep 2
    count = MyModel.find(:count, :conditions=>["name=?", "Beavis"],:consistent_read=>true)
    assert count > 0

    mms = MyModel.find(:all, :conditions=>["name=?", "Beavis"],:consistent_read=>true)
    assert mms.size > 0
    assert_equal mms.size, count

  end

  def test_attributes_correct
    # child should contain child class attributes + parent class attributes

    #MyModel.defined_attributes.each do |a|
    #
    #end
    #MyChildModel.defined_attributes.inspect

  end

  def test_results_array
    mms = MyModel.find(:all,:consistent_read=>true) # select 2
    assert !mms.first.nil?
    assert !mms.last.nil?
    assert !mms.empty?
    assert mms.include?(mms[0])

    assert_equal mms[2, 2].size, 2
    assert_equal mms[2..5].size, 4
    assert_equal mms[2...5].size, 3

  end

  def test_random_index
    create_my_models(120)
    mms = MyModel.find(:all,:consistent_read=>true)
    o = mms[85]
    assert !o.nil?
    o = mms[111]
    assert !o.nil?
  end

  def test_objects_in_constructor
    mm = MyModel.new(:name=>"model1")
    mm.save
    # my_model should be treated differently since it's a belong_to
    mcm = MyChildModel.new(:name=>"johnny", :my_model=>mm)
    mcm.save
    sleep(1) #needed because mcm.my_model below does not have :consistent_read set

    assert mcm.my_model != nil

    mcm = MyChildModel.find(mcm.id,:consistent_read=>true)
    assert mcm.my_model != nil

  end


  def test_nil_attr_deletion
    mm = MyModel.new
    mm.name = "Chad"
    mm.age = 30
    mm.cool = false
    mm.save

    # Should have 1 age attribute
    sdb_atts = @@sdb.get_attributes('simplerecord_tests_my_models', mm.id, 'age',true) # consistent_read
    assert_equal sdb_atts[:attributes].size, 1

    mm.age = nil
    mm.save

    # Should be NIL
    assert_equal mm.age, nil

    sleep 1 #doesn't seem to be respecting consistent_read below
    # Should have NO age attributes
    assert_equal @@sdb.get_attributes('simplerecord_tests_my_models', mm.id, 'age',true)[:attributes].size, 0
  end

  def test_null
    MyModel.delete_domain
    MyModel.create_domain

    mm = MyModel.new(:name=>"birthay is null")
    mm.save
    mm2 = MyModel.new(:name=>"birthday is not null")
    mm2.birthday = Time.now
    mm2.save
    mms = MyModel.find(:all, :conditions=>["birthday is null"],:consistent_read=>true)
    mms.each do |m|
      m.inspect
    end
    assert_equal 1, mms.size
    assert_equal mms[0].id, mm.id
    mms = MyModel.find(:all, :conditions=>["birthday is not null"],:consistent_read=>true)
    mms.each do |m|
      m.inspect
    end
    assert_equal 1, mms.size
    assert_equal mms[0].id, mm2.id
  end

  # Test to add support for IN
  def test_in_clause
#        mms = MyModel.find(:all,:consistent_read=>true)

#        mms2 = MyModel.find(:all, :conditions=>["id in ?"],:consistent_read=>true)

  end

  def test_base_attributes
    mm = MyModel.new()
    mm.name = "test name tba"
    mm.base_string = "in base class"
    mm.save_with_validation!

    mm2 = MyModel.find(mm.id,:consistent_read=>true)
    assert_equal mm2.base_string, mm.base_string
    assert_equal mm2.name, mm.name
    assert_equal mm2.id, mm.id
    mm2.name += " 2"

    mm2.base_string = "changed base string"
    mm2.save_with_validation!

    mm3 = MyModel.find(mm2.id,:consistent_read=>true)
    assert_equal mm3.base_string, mm2.base_string
  end

  def test_dates
    mm = MyModel.new()
    mm.name = "test name td"
    mm.date1 = Date.today
    mm.date2 = Time.now
    mm.date3 = DateTime.now
    mm.save

    mm = MyModel.find(:first, :conditions=>["date1 >= ?", 1.days.ago.to_date],:consistent_read=>true)
    assert mm.is_a? MyModel

    mm = MyModel.find(:first, :conditions=>["date2 >= ?", 1.minutes.ago],:consistent_read=>true)
    assert mm.is_a? MyModel

    mm = MyModel.find(:first, :conditions=>["date3 >= ?", 1.minutes.ago],:consistent_read=>true)
    assert mm.is_a? MyModel

  end

  def test_attr_encrypted
    require_relative 'models/model_with_enc'
    ssn = "123456789"
    password = "my_password"

    ob = ModelWithEnc.new
    ob.name = "my name"
    ob.ssn = ssn
    ob.password = password
    assert_equal ssn, ob.ssn
    assert password != ob.password # we know this doesn't work right
    assert_equal ob.password, password
    ob.save

    # try also with constructor, just to be safe
    ob = ModelWithEnc.create(:ssn=>ssn, :name=>"my name", :password=>password)
    assert_equal ssn, ob.ssn
    assert password != ob.password # we know this doesn't work right
    assert_equal ob.password, password
    assert_equal ssn, ob.ssn
    assert_equal ob.password, password

    ob2 = ModelWithEnc.find(ob.id,:consistent_read=>true)
    assert_equal ob2.name, ob.name
    assert_equal ob2.ssn, ob.ssn
    assert_equal ob2.ssn, ssn
    assert_equal ob2.password, password
    assert ob2.attributes["password"] != password
    assert_equal ob2.password, ob.password
  end

  def test_non_persistent_attributes
    mm = MyModel.new({:some_np_att=>"word"})
    mm = MyModel.new({"some_other_np_att"=>"up"})

  end
def test_atts_using_strings_and_symbols
    mm = MyModel.new({:name=>"mynamex1",:age=>32})
    mm2 = MyModel.new({"name"=>"mynamex2","age"=>32})
    assert_equal(mm.age, mm2.age)

    mm.save
    mm2.save

    mm = MyModel.find(mm.id,:consistent_read=>true)
    mm2 = MyModel.find(mm2.id,:consistent_read=>true)
    assert_equal(mm.age, mm2.age)
  end

  def test_constructor_using_belongs_to_ids
    mm = MyModel.new({:name=>"myname tcubti"})
    mm.save
    sleep(1) #needed because mm2.my_model below does not have :consistent_read set

    mm2 = MyChildModel.new({"name"=>"myname tcubti 2", :my_model_id=>mm.id})
    assert_equal mm.id, mm2.my_model_id, "#{mm.id} != #{mm2.my_model_id}"
    mm3 = mm2.my_model
    assert_equal mm.name, mm3.name

    mm3 = MyChildModel.create(:my_model_id=>mm.id, :name=>"myname tcubti 3")

    mm4 = MyChildModel.find(mm3.id,:consistent_read=>true)
    assert_equal mm4.my_model_id, mm.id
    assert !mm4.my_model.nil?

  end

  def test_update_attributes
    mm = MyModel.new({:name=>"myname tua"})
    mm.save

    now = Time.now
    mm.update_attributes(:name=>"name2", :age=>21, "date2"=>now)
    assert_equal mm.name, "name2"
    assert_equal mm.age, 21

    mm = MyModel.find(mm.id,:consistent_read=>true)
    assert_equal mm.name, "name2"
    assert_equal mm.age, 21
  end

  def test_explicit_class_name
    mm = MyModel.new({:name=>"myname tecn"})
    mm.save

    mm2 = MyChildModel.new({"name"=>"myname tecn 2"})
    mm2.x = mm
    assert_equal mm2.x.id, mm.id
    mm2.save

    sleep 1 #sometimes consistent_read isn't good enough. Why? Dunno.
    mm3 = MyChildModel.find(mm2.id,:consistent_read=>true)
    assert_equal mm3.x.id, mm.id
  end

  def test_storage_format

    mm = MyModel.new({:name=>"myname tsf"})
    mm.date1 = Time.now
    mm.date2 = DateTime.now
    mm.save

    raw = @@sdb.get_attributes(MyModel.domain, mm.id, nil, true)
    puts raw.inspect #observation interferes with this in some way
    assert_equal raw[:attributes]["updated"][0].size, "2010-01-06T16:04:23".size
    assert_equal raw[:attributes]["date1"][0].size, "2010-01-06T16:04:23".size
    assert_equal raw[:attributes]["date2"][0].size, "2010-01-06T16:04:23".size

  end

  def test_empty_initialize
    mm = MyModel.new

    mme = ModelWithEnc.new
    mme = ModelWithEnc.new(:ssn=>"", :password=>"") # this caused encryptor errors
    mme = ModelWithEnc.new(:ssn=>nil, :password=>nil)
  end

  def test_string_ints
    mm = MyModel.new
    mm.name = "whenever"
    mm.age = "1"

    mm2 = MyModel.new
    mm2.name = "whenever2"
    mm2.age = 1
    params = {:name=>"scooby", :age=>"123"}
    mm3 = MyModel.new(params)

    assert_equal mm.age, 1
    assert_equal mm2.age, 1
    assert_equal mm3.age, 123

    mm.save!
    mm2.save!
    mm3.save!

    assert_equal mm.age, 1
    assert_equal mm2.age, 1
    assert_equal mm3.age, 123

    mmf1 = MyModel.find(mm.id,:consistent_read=>true)
    mmf2 = MyModel.find(mm2.id,:consistent_read=>true)
    mmf3 = MyModel.find(mm3.id,:consistent_read=>true)

    assert_equal mmf1.age, 1
    assert_equal mmf2.age, 1
    assert_equal mmf3.age, 123

    mmf1.update_attributes({:age=>"456"})

    assert_equal mmf1.age, 456
  end

  def test_box_usage
    mm = MyModel.new
    mm.name = "however"
    mm.age = "1"
    mm.save

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

    mm = MyModel.find(mm.id,:consistent_read=>true)
    # Values are not returned in order
    assert_equal val, mm.name.sort
    assert_equal val2, mm.age.sort
  end

  def test_zzz_last_batter_up
    MyModel.delete_domain
    MyChildModel.delete_domain
    ModelWithEnc.delete_domain
  end

end
