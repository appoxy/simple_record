module SimpleRecord
    module Json

        def self.included(base)
            base.extend ClassMethods
        end

        module ClassMethods

            def json_create(object)
                obj = new
                for key, value in object
                    next if key == 'json_class'
                    obj.set key, value
                end
                obj
            end

            def from_json(json_string)
                return JSON.parse(json_string)
            end

        end

        def to_json(*a)
            result = {
                    'json_class' => self.class.name,
                    'id' => self.id
            }
            defined_attributes_local.each_pair do |name, val|
#                puts name.to_s + "=" + val.inspect
                if val.type == :belongs_to
                    result[name.to_s + "_id"] = get_attribute_sdb(name)
                else
                    result[name] = get_attribute(name)
                end
#                puts 'result[name]=' + result[name].inspect
            end

            result.to_json(*a)
        end

    end
end
