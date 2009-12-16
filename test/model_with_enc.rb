require 'attr_encrypted'

class ModelWithEnc < SimpleRecord::Base
    has_strings :name,
                {:name=>:ssn, :encrypted=>true, :encryption_key=>"simple_record_test_key"},
                {:name=>:password, :hashed=>true}
end