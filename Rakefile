# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/simple_record.rb'

#Hoe.spec('simple_record') do |p|
#  p.rubyforge_name = 'spacegems' # if different than lowercase project name
#  p.developer('Travis Reeder', 'travis@crankapps.com')
#    # , SimpleRecord::VERSION
#end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "simple_record"
    gemspec.summary = "Drop in replacement for ActiveRecord to Amazon SimpleDB instead."
    gemspec.email = "travis@appoxy.com"
    gemspec.homepage = "http://github.com/appoxy/simple_record/"
    gemspec.description = "Drop in replacement for ActiveRecord to Amazon SimpleDB instead."
    gemspec.authors = ["Travis Reeder","RightScale"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

# vim: syntax=Ruby
