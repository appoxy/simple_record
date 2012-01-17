require "yaml"
require 'aws'

require_relative "test_base"
require_relative "../lib/simple_record"
require_relative 'models/my_model'
require_relative 'models/my_child_model'

class ConversionsTest < TestBase

    def test_ints
        x = 0
        assert_equal "09223372036854775808", SimpleRecord::Translations.pad_and_offset(x)

        x = 1
        assert_equal "09223372036854775809", SimpleRecord::Translations.pad_and_offset(x)

        x = "09223372036854775838"
        assert_equal 30, SimpleRecord::Translations.un_offset_int(x)
    end

    def test_float
        assert_equal 0.0, SimpleRecord::Translations.pad_and_offset("0.0".to_f)
    end
end
