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
        name = "joe" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        nickname = "blow" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        mm = MyModel.create :name=>name, :nickname=>nickname
        mm.save
        sleep 1
        assert mm.name == name
        assert mm.nickname == nickname
        mm2 = MyModel.find(mm.id)
        assert mm2.name == name
        assert mm2.nickname == nickname
    end

    def test_utf8_http_post
        name = "jos\u00E9" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        nickname = "??" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        mm = MyModel.create :name=>name, :nickname=>nickname
        mm.save
        sleep 1
        assert mm.name == name
        assert mm.nickname == nickname
        mm2 = MyModel.find(mm.id)
        assert mm2.name == name
        assert mm2.nickname == nickname
    end

end
