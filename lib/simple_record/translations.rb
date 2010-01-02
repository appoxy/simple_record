# This module defines all the methods that perform data translations for storage and retrieval.
module SimpleRecord
    module Translations

        @@offset = 9223372036854775808
        @@padding = 20
        @@date_format = "%Y-%m-%dT%H:%M:%S"; # Time to second precision

        def ruby_to_sdb(name, value)

            return nil if value.nil?

            name = name.to_s

#            puts "Converting #{name} to sdb value=#{value}"
#            puts "atts_local=" + defined_attributes_local.inspect

            att_meta = defined_attributes_local[name.to_sym]

            if att_meta.type == :int
                ret = Translations.pad_and_offset(value)
            elsif att_meta.type == :date
                ret = Translations.pad_and_offset(value)
            else
                ret = value.to_s
            end


            if att_meta.options
                if att_meta.options[:encrypted]
#                    puts "ENCRYPTING #{name} value #{value}"
                    ret = Translations.encrypt(ret, att_meta.options[:encrypted])
#                    puts 'encrypted value=' + ret.to_s
                end
                if att_meta.options[:hashed]
                    ret = Translations.pass_hash(ret)
                end
            end

            return ret.to_s

        end


        # Convert value from SimpleDB String version to real ruby value.
        def sdb_to_ruby(name, value)
#            puts 'sdb_to_ruby arg=' + name.inspect + ' - ' + name.class.name + ' - value=' + value.to_s
            return nil if value.nil?
            att_meta = defined_attributes_local[name.to_sym]

            if att_meta.options
                if att_meta.options[:encrypted]
                    value = Translations.decrypt(value, att_meta.options[:encrypted])
                end
                if att_meta.options[:hashed]
                    return PasswordHashed.new(value)
                end
            end

            if att_meta.type == :int
                value = Translations.un_offset_int(value)
            elsif att_meta.type == :date
                value = to_date(value)
            elsif att_meta.type == :boolean
                value = to_bool(value)
            end
            value
        end


        def self.pad_and_offset(x) # Change name to something more appropriate like ruby_to_sdb
            # todo: add Float, etc
            #    puts 'padding=' + x.class.name + " -- " + x.inspect
            if x.kind_of? Integer
                x += @@offset
                x_str = x.to_s
                # pad
                x_str = '0' + x_str while x_str.size < 20
                return x_str
            elsif x.respond_to?(:iso8601)
                #  puts x.class.name + ' responds to iso8601'
                #
                # There is an issue here where Time.iso8601 on an incomparable value to DateTime.iso8601.
                # Amazon suggests: 2008-02-10T16:52:01.000-05:00
                #                  "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                #
                if x.is_a? DateTime
                    x_str = x.getutc.strftime(@@date_format)
                elsif x.is_a? Time
                    x_str = x.getutc.strftime(@@date_format)
                elsif x.is_a? Date
                    x_str = x.strftime(@@date_format)

                end
                return x_str
            else
                return x
            end
        end


        def wrap_if_required(arg, value, sdb_val)
            return nil if value.nil?

            att_meta = defined_attributes_local[arg.to_sym]
            if att_meta && att_meta.options
                if att_meta.options[:hashed]
#                    puts 'wrapping ' + arg_s
                    return PasswordHashed.new(sdb_val)
                end
            end
            value
        end

        def to_date(x)
            if x.is_a?(String)
                DateTime.parse(x)
            else
                x
            end
        end

        def to_bool(x)
            if x.is_a?(String)
                x == "true" || x == "1"
            else
                x
            end
        end

        def self.un_offset_int(x)
            if x.is_a?(String)
                x2 = x.to_i
#            puts 'to_i=' + x2.to_s
                x2 -= @@offset
#            puts 'after subtracting offset='+ x2.to_s
                x2
            else
                x
            end
        end

        def unpad(i, attributes)
            if !attributes[i].nil?
#          puts 'before=' + self[i].inspect
                attributes[i].collect!{ |x|
                    un_offset_int(x)

                }
            end
        end

        def unpad_self
            defined_attributes_local.each_pair do |name, att_meta|
                if att_meta.type == :int
                    unpad(name, @attributes)
                end
            end
        end


        def self.encrypt(value, key=nil)
            key = key || get_encryption_key()
            raise SimpleRecordError, "Encryption key must be defined on the attribute." if key.nil?
            encrypted_value = SimpleRecord::Encryptor.encrypt(:value => value, :key => key)
            encoded_value = Base64.encode64(encrypted_value)
            encoded_value
        end


        def self.decrypt(value, key=nil)
#            puts "decrypt orig value #{value} "
            unencoded_value = Base64.decode64(value)
            raise SimpleRecordError, "Encryption key must be defined on the attribute." if key.nil?
            key = key || get_encryption_key()
#            puts "decrypting #{unencoded_value} "
            decrypted_value = SimpleRecord::Encryptor.decrypt(:value => unencoded_value, :key => key)
#             "decrypted #{unencoded_value} to #{decrypted_value}"
            decrypted_value
        end


        def pad_and_offset_ints_to_sdb()

#            defined_attributes_local.each_pair do |name, att_meta|
#                if att_meta.type == :int && !self[name.to_s].nil?
#                    arr = @attributes[name.to_s]
#                    arr.collect!{ |x| self.class.pad_and_offset(x) }
#                    @attributes[name.to_s] = arr
#                end
#            end
        end

        def convert_dates_to_sdb()

#            defined_attributes_local.each_pair do |name, att_meta|
#          puts 'int encoding: ' + i.to_s

#            end
        end

        def self.pass_hash(value)
            hashed = Password::create_hash(value)
            encoded_value = Base64.encode64(hashed)
            encoded_value
        end

        def self.pass_hash_check(value, value_to_compare)
            unencoded_value = Base64.decode64(value)
            return Password::check(value_to_compare, unencoded_value)
        end

    end


    class PasswordHashed

        def initialize(value)
            @value = value
        end

        def hashed_value
            @value
        end

        # This allows you to compare an unhashed string to the hashed one.
        def ==(val)
            if val.is_a?(PasswordHashed)
                return val.hashed_value == self.hashed_value
            end
            return Translations.pass_hash_check(@value, val)
        end

        def to_s
            @value
        end
    end

end