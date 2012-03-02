require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")
require "yaml"
require 'aws'
require_relative 'models/my_simple_model'
require 'active_support'
require 'test_base'


class TestEncodings < TestBase

    def test_aaa_setup_delete_domain
        MySimpleModel.delete_domain
        MySimpleModel.create_domain
    end
    def test_ascii_http_post
        name = "joe" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        nickname = "blow" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        mm = MySimpleModel.create :name=>name, :nickname=>nickname
        assert mm.save
        assert_equal mm.name, name
        assert_equal mm.nickname, nickname
        mm2 = MySimpleModel.find(mm.id,:consistent_read=>true)
        assert_equal mm2.name, name
        assert_equal mm2.nickname, nickname
        assert mm2.delete
    end

    def test_utf8_http_post
        name = "jos\u00E9" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        nickname = "??" + ("X" * 1000) # pad the field to help get the URL over the 2000 length limit so AWS uses a POST
        mm = MySimpleModel.create :name=>name, :nickname=>nickname
        assert mm.save
        assert_equal mm.name, name
        assert_equal mm.nickname, nickname
        mm2 = MySimpleModel.find(mm.id,:consistent_read=>true)
        assert_equal mm2.name, name
        assert_equal mm2.nickname, nickname
        assert mm2.delete
    end
    def test_zzz_cleanup_delete_domain
        MySimpleModel.delete_domain
    end
end
