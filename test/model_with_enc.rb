require 'attr_encrypted'

class ModelWithEnc < SimpleRecord::Base
    has_strings :name,
                {:name=>:ssn, :encrypted=>true}
end