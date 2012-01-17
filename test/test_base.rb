gem 'test-unit'
require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require "yaml"
require 'aws'
require_relative 'models/my_model'
require_relative 'models/my_child_model'
#require 'active_support'

class TestBase < Test::Unit::TestCase


    def setup
        reset_connection()

    end

    def teardown
        SimpleRecord.close_connection
    end

    def delete_all(clz)
        obs = clz.find(:all,:consistent_read=>true)
        obs.each do |o|
            o.delete
        end
    end

    def reset_connection(options={})
        @config = YAML::load(File.open(File.expand_path("~/.test_configs/simple_record.yml")))

        SimpleRecord.enable_logging

        SimpleRecord::Base.set_domain_prefix("simplerecord_tests_")
        SimpleRecord.establish_connection(@config['amazon']['access_key'], @config['amazon']['secret_key'],
                                          {:connection_mode=>:per_thread}.merge(options))


        # Establish AWS connection directly
        @@sdb = Aws::SdbInterface.new(@config['amazon']['access_key'], @config['amazon']['secret_key'],
                                      {:connection_mode => :per_thread}.merge(options))

    end


    # Use to populate db
    def create_my_models(count)
        batch = []
        count.times do |i|
            mm = MyModel.new(:name=>"model_#{i}")
            mm.age = i
            batch << mm
        end
        MyModel.batch_save batch
    end


end
