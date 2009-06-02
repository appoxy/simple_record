require 'minitest/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'right_aws'
require 'my_model'
require 'my_child_model'

class TestSimpleRecord < Test::Unit::TestCase

    def setup
        @config = YAML::load(File.read('test-config.yml'))
        puts 'akey=' + @config['amazon']['access_key']
        puts 'skey=' + @config['amazon']['secret_key']
        RightAws::ActiveSdb.establish_connection(@config['amazon']['access_key'], @config['amazon']['secret_key'])
        SimpleRecord::Base.set_domain_prefix("simplerecord_tests_")
    end

    def teardown
        RightAws::ActiveSdb.close_connection()
    end

    def test_save_get
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
        puts mm2.cool.class.name
        assert mm2.id == mm.id
        assert mm2.age == mm.age
        assert mm2.cool == mm.cool
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
        # these DO NOT work right now, all objects get all callbacks
        #	I tried like this, seem to be getting somewhere.
        #
        #  class << self;
        #  @@callbacks.each do |callback|
        #    #we first have to make an initialized array for each of the callbacks, to prevent problems if they are not called
        #    puts 'setting callback ' + callback.to_s + ' on ' + self.inspect
        #    eval %{
        #
        #        # add the methods to the class
        #        def #{callback}(*args)
        #        args.each do |arg|
        #          cb_names = self.instance_variable_get(:@#{callback}_names)
        #          cb_names = [] if cb_names.nil?
        #          cb_names << arg.to_s if cb_names.index(arg.to_s).nil?
        #          self.instance_variable_set(:@#{callback}_names, cb_names)
        #        end
        ##      asdf    @@#{callback}_names=args.map{|arg| arg.to_s}
        #      end
        #
        #        # now we run the methods in the callback array for this class
        #send :define_method, "run_#{callback}" do
        ##        def run_#{callback}
        #          cb_names = self.instance_variable_get(:@#{callback}_names)
        #          cb_names.each { |name|
        #          unless eval(name)
        #            return false
        #          end
        #          }
        #          return true
        #        end
        #    }
        #  end
        #  end
    end
end
