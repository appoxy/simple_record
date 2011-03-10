# -*- ruby -*-

require 'rubygems'
require './lib/simple_record.rb'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "simple_record"
    gemspec.summary = "ActiveRecord like interface for Amazon SimpleDB. By http://www.appoxy.com"
    gemspec.email = "travis@appoxy.com"
    gemspec.homepage = "http://github.com/appoxy/simple_record/"
    gemspec.description = "ActiveRecord like interface for Amazon SimpleDB. Store, query, shard, etc. By http://www.appoxy.com"
    gemspec.authors = ["Travis Reeder", "Chad Arimura", "RightScale"]
    gemspec.files = FileList['lib/**/*.rb']
    gemspec.add_dependency 'aws'
    gemspec.add_dependency 'concur'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

# vim: syntax=Ruby
