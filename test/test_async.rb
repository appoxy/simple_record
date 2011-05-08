require 'rspec'
require File.join(File.dirname(__FILE__), "/../lib/simple_record")
require File.join(File.dirname(__FILE__), "./test_helpers")
require_relative "test_base"
require "yaml"
require 'aws'
require_relative 'my_model'
require_relative 'my_child_model'
require_relative 'model_with_enc'
require_relative 'my_simple_model'


describe "async" do
  before(:all) do
    @config = YAML::load(File.open(File.expand_path("~/.test_configs/simple_record.yml")))
    #puts 'inspecting config = ' + @config.inspect

    SimpleRecord::Base.set_domain_prefix("simplerecord_tests_")
    SimpleRecord.establish_connection(@config['amazon']['access_key'], @config['amazon']['secret_key'],
                                      {:connection_mode=>:per_thread})


    # Establish AWS connection directly
    @@sdb = Aws::SdbInterface.new(@config['amazon']['access_key'], @config['amazon']['secret_key'],
                                  {:connection_mode => :per_thread}.merge(options))
  end
  describe "find" do
    it "should be able to find in parallel" do
      model = MySimpleModel.new
    end
  end
end

