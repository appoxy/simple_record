require "yaml"
require 'aws'

require_relative "test_base"
require_relative "../lib/simple_record"
require_relative 'my_model'
require_relative 'my_child_model'

class ConversionsTest < TestBase

    def test_ints
        x = 0
        puts SimpleRecord::Translations.pad_and_offset(x)
        assert_equal "09223372036854775808", SimpleRecord::Translations.pad_and_offset(x)

        x = 1
        puts SimpleRecord::Translations.pad_and_offset(x)
        assert_equal "09223372036854775809", SimpleRecord::Translations.pad_and_offset(x)

        x = "09223372036854775838"
        puts SimpleRecord::Translations.un_offset_int(x)
        assert_equal 30, SimpleRecord::Translations.un_offset_int(x)
    end

    # All from examples here: http://tools.ietf.org/html/draft-wood-ldapext-float-00
    def test_floats
        zero = "3 000 0.0000000000000000"
        assert_equal zero, SimpleRecord::Translations.pad_and_offset(0.0)

        puts 'induced = ' + "3.25e5".to_f.to_s

        assert_equal "5 005 3.2500000000000000", SimpleRecord::Translations.pad_and_offset("3.25e5".to_f)
        assert_equal "4 994 8.4000000000000000", SimpleRecord::Translations.pad_and_offset("8.4e-5".to_f)
        assert_equal "4 992 8.4000000000000000", SimpleRecord::Translations.pad_and_offset("8.4e-7".to_f)
        assert_equal "3 000 0.0000000000000000", SimpleRecord::Translations.pad_and_offset("0.0e0".to_f)
        assert_equal "2 004 5.7500000000000000", SimpleRecord::Translations.pad_and_offset("-4.25e-4".to_f)
        assert_equal "2 004 3.6500000000000000", SimpleRecord::Translations.pad_and_offset("-6.35e-4".to_f)
        assert_equal "2 003 3.6500000000000000", SimpleRecord::Translations.pad_and_offset("-6.35e-3".to_f)
        assert_equal "1 895 6.0000000000000000", SimpleRecord::Translations.pad_and_offset("-4.0e105".to_f)
        assert_equal "1 894 6.0000000000000000", SimpleRecord::Translations.pad_and_offset("-4.0e105".to_f)
        assert_equal "1 894 4.0000000000000000", SimpleRecord::Translations.pad_and_offset("-6.0e105".to_f)

    end
end