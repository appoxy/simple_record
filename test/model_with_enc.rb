
class ModelWithEnc < SimpleRecord::Base
    has_strings :name,
                {:name=>:ssn, :encrypted=>"simple_record_test_key"},
                {:name=>:password, :hashed=>true}
end
