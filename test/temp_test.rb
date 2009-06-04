# rubymine won't run 1.9 tests

require 'minitest/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'right_aws'
require 'my_model'
require 'my_child_model'


def setup
    @config = YAML::load(File.read('test-config.yml'))
    puts 'akey=' + @config['amazon']['access_key']
    puts 'skey=' + @config['amazon']['secret_key']
    RightAws::ActiveSdb.establish_connection(@config['amazon']['access_key'], @config['amazon']['secret_key'], :port=>80, :protocol=>"http")
    SimpleRecord::Base.set_domain_prefix("simplerecord_tests_")
end

def teardown
    RightAws::ActiveSdb.close_connection()
end

def test_dates
    mm = MyModel.new
    mm.name = "Travis"
    mm.age = 32
    mm.cool = true
    mm.created = DateTime.now - 10
    mm.updated = DateTime.now
    mm.birthday = Time.now - (3600 * 24 * 365 * 10)
    puts 'before save=' + mm.inspect
    mm.save
    puts 'after save=' + mm.inspect

    mms = MyModel.find(:all, :conditions => ["created > ?", DateTime.now - 1])
    puts 'mms=' + mms.inspect

end

def test_date_comparisons

    t = SimpleRecord::Base.pad_and_offset(Time.now)
    puts t
    dt = SimpleRecord::Base.pad_and_offset(DateTime.now)
    puts dt
    dt_tomorrow = SimpleRecord::Base.pad_and_offset(DateTime.now + 1)


    puts 'compare=' + (t <=> dt).to_s
    puts 'compare=' + (t <=> dt_tomorrow).to_s

    dts = DateTime.parse(dt_tomorrow)
    puts dts.to_s
    ts = Time.parse(dt)
    puts ts.to_s
end

setup

#test_dates
    test_date_comparisons

teardown
