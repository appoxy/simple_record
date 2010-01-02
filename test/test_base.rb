require 'test/unit'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require "yaml"
require 'aws'
require 'my_model'
require 'my_child_model'
require 'active_support'

class TestBase < Test::Unit::TestCase

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


end