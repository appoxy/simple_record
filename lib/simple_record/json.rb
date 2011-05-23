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
          if key == 'id'
            obj.id = value
            next
          end
          obj.set key, value
        end
        obj
      end

      def from_json(json_string)
        return JSON.parse(json_string)
      end

    end

    def as_json(options={})
      puts 'SimpleRecord as_json called with options: ' + options.inspect
      result = {
          'id' => self.id
      }
      result['json_class'] = self.class.name unless options && options[:exclude_json_class]
      defined_attributes_local.each_pair do |name, val|
#                puts name.to_s + "=" + val.inspect
        if val.type == :belongs_to
          result[name.to_s + "_id"] = get_attribute_sdb(name)
        else
          result[name] = get_attribute(name)
        end
#                puts 'result[name]=' + result[name].inspect
      end
#            ret = result.as_json(options)
#            puts 'ret=' + ret.inspect
#            return ret
      result
    end

  end
end
