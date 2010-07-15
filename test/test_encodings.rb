require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'aws'
require 'my_model'
require 'my_child_model'
require 'active_support'
require 'test_base'


class Person < SimpleRecord::Base
    has_strings :name, :i_as_s
    has_ints :age
end
class TestEncodings < TestBase

    def test_ascii_http_post
        first_name = "joe" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        last_name = "blow" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        mm = MyModel.create :first_name=>first_name, :last_name=>last_name
        mm.save
        sleep 1
        assert mm.first_name == first_name
        assert mm.last_name == last_name
        mm2 = MyModel.find(mm.id)
        assert mm2.first_name == first_name
        assert mm2.last_name == last_name
    end

    def test_utf8_http_post
        first_name = "josé" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        last_name = "??" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        mm = MyModel.create :first_name=>first_name, :last_name=>last_name
        mm.save
        sleep 1
        assert mm.first_name == first_name
        assert mm.last_name == last_name
        mm2 = MyModel.find(mm.id)
        assert mm2.first_name == first_name
        assert mm2.last_name == last_name
    end

end