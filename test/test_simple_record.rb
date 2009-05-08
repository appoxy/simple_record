require "test/unit"
require "simple_record"

class TestSimpleRecord < Test::Unit::TestCase
  def test_sanity
    flunk "write tests or I will kneecap you"
  end
  
  def test_callbacks
    # these DO NOT work right now, all objects get all callbacks
	=begin
	I tried like this, seem to be getting somewhere.
	
  class << self;
  @@callbacks.each do |callback|
    #we first have to make an initialized array for each of the callbacks, to prevent problems if they are not called
    puts 'setting callback ' + callback.to_s + ' on ' + self.inspect
    eval %{

        # add the methods to the class
        def #{callback}(*args)
        args.each do |arg|
          cb_names = self.instance_variable_get(:@#{callback}_names)
          cb_names = [] if cb_names.nil?
          cb_names << arg.to_s if cb_names.index(arg.to_s).nil?
          self.instance_variable_set(:@#{callback}_names, cb_names)
        end
#      asdf    @@#{callback}_names=args.map{|arg| arg.to_s}
      end

        # now we run the methods in the callback array for this class
send :define_method, "run_#{callback}" do
#        def run_#{callback}
          cb_names = self.instance_variable_get(:@#{callback}_names)
          cb_names.each { |name|
          unless eval(name)
            return false
          end
          }
          return true
        end
    }
  end
  end
	=end
  end
end
