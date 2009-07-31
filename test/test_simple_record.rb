require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'right_aws'
require 'my_model'
require 'my_child_model'

class TestSimpleRecord < Test::Unit::TestCase

    def setup
        @config = YAML::load(File.open(File.expand_path("~/.amazon/simple_record_tests.yml")))
        #puts @config.inspect
        SimpleRecord.establish_connection(@config['amazon']['access_key'], @config['amazon']['secret_key'], :port=>80, :protocol=>"http")
        SimpleRecord::Base.set_domain_prefix("simplerecord_tests_")
    end

    def teardown
        SimpleRecord.close_connection()
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
    end

    def test_bad_query
        assert_raise RightAws::AwsError do
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
            puts 'new=' + new_item.inspect
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

        # todo: how do we assert this?

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
        count = MyModel.find(:count)
        assert count > 0
    end

    def test_attributes_correct

        #MyModel.defined_attributes.each do |a|
        #
        #end
        #MyChildModel.defined_attributes.inspect

    end


    # ensures that it uses next token and what not
    def test_big_result
        #110.times do |i|
        #    MyModel
        #end
        #rs = MyModel.find(:all, :limit=>300)
        #rs.each do |x|
        #   puts 'x=' + x.id
        #end
    end
end
