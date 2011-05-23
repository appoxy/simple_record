# SimpleRecord - ActiveRecord for SimpleDB

An ActiveRecord interface for SimpleDB.  Can be used as a drop in replacement for ActiveRecord in rails.

Brought to you by: [![Appoxy](https://lh5.googleusercontent.com/_-J9DSaseOX8/TX2Bq564w-I/AAAAAAAAxYU/xjeReyoxa8o/s800/appoxy-small%20%282%29.png)](http://www.appoxy.com)

## Discussion Group

<http://groups.google.com/group/simple-record>

## Getting Started

1. Install

    gem install simple_record

2. Create a model

        require 'simple_record'
    
        class MyModel < SimpleRecord::Base
           has_strings :name
           has_ints :age
        end

More about ModelAttributes below.

3. Setup environment

        AWS_ACCESS_KEY_ID='XXXX'
        AWS_SECRET_ACCESS_KEY='YYYY'
        SimpleRecord.establish_connection(AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY)

4. Go to town

        # Store a model object to SimpleDB
        mm = MyModel.new
        mm.name = "Travis"
        mm.age = 32
        mm.save
        id = mm.id

        # Get an object from SimpleDB
        mm2 = MyModel.find(id)
        puts 'got=' + mm2.name + ' and he/she is ' + mm.age.to_s + ' years old'
        # Or more advanced queries? mms = MyModel?.find(:all, ["age=?", 32], :order=>"name", :limit=>10)

That's literally all you need to do to get started. No database install, no other setup required.

## Attributes and modifiers for models

NOTE: All objects will automatically have :id, :created, :updated attributes.

### has_strings

Add string attributes.

    class MyModel < SimpleRecord::Base
      has_strings :name
    end

### has_ints, has_dates and has_booleans

This is required because SimpleDB only has strings so SimpleRecord needs to know how to convert, pad, offset, etc.

    class MyModel < SimpleRecord::Base
      has_strings :name
      has_ints :age, :height
      has_dates :birthday
      has_booleans :is_nerd
    end

### Multi-value attributes

SimpleDB supports having multiple values for the same attribute so to use this feature, simply set an attribute to an
array of values.

### belongs_to

Creates a many-to-one relationship. Can only have one per belongs_to call.

    class MyModel < SimpleRecord::Base
        belongs_to :school
        has_strings :name
        has_ints :age, :height
        has_dates :birthday
        has_booleans :is_nerd
    end

Which requires another class called 'School' or you can specify the class explicitly with:

    belongs_to :school, :class_name => "Institution"

### set_table_name or set_domain_name

If you want to use a custom domain for a model object, you can specify it with set_table_name (or set_domain_name).

    class SomeModel < SimpleRecord::Base
        set_table_name :different_model
    end


## Querying

Querying is similar to ActiveRecord for the most part.

To find all objects that match conditions returned in an Array:

    Company.find(:all, :conditions => ["created > ?", 10.days.ago], :order=>"name", :limit=>50)

To find a single object:

    Company.find(:first, :conditions => ["name = ? AND division = ? AND created > ?", "Appoxy", "West", 10.days.ago ])

To count objects:

    Company.find(:count, :conditions => ["name = ? AND division = ? AND created > ?", "Appoxy", "West", 10.days.ago ])

You can also the dynamic method style, for instance the line below is the same as the Company.find(:first....) line above:

    Company.find_by_name_and_division("Appoxy", "West")

To find all:

    Company.find_all_by_name_and_division("Appoxy", "West")

Consistent read:

    Company.find(:all, :conditions => ["created > ?", 10.days.ago], :order=>"name", :limit=>50, :consistent_read=>true)

There are so many different combinations of the above for querying that I can't put them all here,
but this should get you started.

You can get more ideas from here: http://api.rubyonrails.org/classes/ActiveRecord/Base.html. Not everything is supported
but a lot is.

### Pagination

SimpleRecord has paging built in and acts much like will_paginate:

    MyModel.paginate(:page=>2, :per_page=>30 [, the other normal query options like in find()])

That will return results 30 to 59.

## Configuration

### Domain Prefix

To set a global prefix across all your models, use:

    SimpleRecord::Base.set_domain_prefix("myprefix_")

### Connection Modes

There are 3 different connection modes:

* per_request (default) - opens and closes a new connection to simpledb for every simpledb request. Not the best performance, but it's safe and can handle many concurrent requests at the same time (unlike single mode).
* single - one connection across the entire application, not recommended unless the app is used by a single person.
* per_thread - a connection is used for every thread in the application. This is good, but the catch is that you have to ensure to close the connection.

You set the mode when you call establish_connection:

    SimpleRecord.establish_connection(AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY, :connection_mode=>:per_thread)

We recommend per_thread with explicitly closing the connection after each Rails request (not to be mistaken for a SimpleDB request) or pool for rails apps.

For rails, be sure to add this to your Application controller if using per_thread mode:

    after_filter :close_sdb_connection

    def close_sdb_connection
        SimpleRecord.close_connection
    end

### LOB and any other S3 Storage

    :s3_bucket=>...

* :old (default) will use the existing lob location of "#{aws_access_key}_lobs", but any new features will use the :new bucket.
* :new will use the new and recommended s3 bucket location of "simple_record_#{aws_access_key}".
* Any string value will use that value as the bucket name.


NOTE: All projects should set this as we may make this default in a future major version (v3?). Existing projects should use
:s3_bucket=>:

### Created and Updated At Columns

The default uses the columns "created" and "updated" which unfortunately are not the same as ActiveRecord, which
uses created_at and updated_at. Although you can use created_at and updated_at methods, you may still want the columns in
SimpleDB to be created_at and updated_at.

    :created_col=>"created", :updated_col=>"updated"

NOTE: All projects should set these as we may make the "_at" postfix default in a future major version (v3?). Existing
projects should set :created_col=>"created", :updated_col=>"updated" (default) so if it changes in a future version,
there won't be any issues.

## SimpleRecord on Rails

You don't really have to do anything except have your models extends SimpleRecord::Base instead of ActiveRecord::Base, but here are some tips you can use.

### Change Connection Mode

Use per_thread connection mode and close the connection after each request.

    after_filter :close_sdb_connection

    def close_sdb_connection
        SimpleRecord.close_connection
    end

### Disable ActiveRecord so you don't have to setup another database

#### Rails 2

This is most helpful on windows so Rails doesn't need sqlite or mysql gems/drivers installed which are painful to install on windows.
In environment.rb, add 'config.frameworks -= [ :active_record ]', so it should look something like:

    Rails::Initializer.run do |config|
      config.frameworks -= [ :active_record ]
      ....
    end

#### Rails 3

At the top of application.rb, comment out `require 'rails/all` and add the following:

    #require 'rails/all'
    %w(
      action_controller
      action_mailer
      active_resource
      rails/test_unit
    ).each do |framework|
      begin
        require "#{framework}/railtie"
      rescue LoadError
      end
    end

This is the same as rails/all minus active_record.

## Large Objects (LOBS)

Typical databases support BLOB's and/or CLOB's, but SimpleDB has a 1024 character per attribute maximum so larger
values should be stored in S3. Fortunately SimpleRecord takes care of this for you by defining has_clobs for a large
string value. There is no support for blobs yet.

    has_clobs :my_clob

These clob values will be stored in s3 under a bucket named "#{aws_access_key}_lobs"
OR "simple_record_#{aws_access_key}/lobs" if you set :s3_bucket=>:new in establish_connection (RECOMMENDED).

If you have more than one clob on an object and if it makes sense for performance reasons, you can set a configuration option on the class to store all clobs
as one item on s3 which means it will do a single put to s3 and a single get for all the clobs on the object.
This would generally be good for somewhat small clob values or when you know you will always be accessing
all the clobs on the object. 

    sr_config :single_clob=>true

Setting this will automatically use :s3_bucket=>:new as well.

## JSON Support

You can easily marshal and unmarshal SimpleRecord objects and results by calling `to_json` on them. The default
serialization will include a `json_class` value which will be used when deserializing to find the class. If you're using
the results in an API though, you may not want to include json_class because the receiving end may not have that class
around, so you can pass in `:exclude_json_class` option to to_json, eg:

    my_ob.to_json(:exclude_json_class=>true)

## Tips and Tricks and Things to Know

### Automagic Stuff


#### Automatic common fields

Every object will automatically get the following attributes so you don't need to define them:

  * id - UUID string
  * created - set when first save
  * updated - set every time you save/update


#### belongs_to foreign keys/IDs are accessible without touching the database

If you had the following in your model:

    belongs_to :something

Then in addition to being able to access the something object with:

    o.something

or setting it with:

    o.something = someo
    
You can also access the ID for something directly with:

    o.something_id

or

    o.something_id = x

Accessing the id can prevent a database call so if you only need the ID, then you
should use this.

## Batch Save

To do a batch save using SimpleDB's batch saving feature to improve performance, simply create your objects, add them to an array, then call:

    MyClass.batch_save(object_list)

## Batch Delete

To do a batch delete using SimpleDB's batch delete feature to improve performance, simply create your objects, add them to an array, then call:

    MyClass.batch_delete(object_list or list_of_ids)

## Operations across a Query

    MyClass.delete_all(find_options)
    MyClass.destroy_all(find_options)

find_options can include anything you'd add after a find(:all, find_options) including :conditions, :limit, etc.

## Caching

You can use any cache that supports the ActiveSupport::Cache::Store interface.

    SimpleRecord::Base.cache_store = my_cache_store

If you want a simple in memory cache store that supports max cache size and expiration, try: <http://gemcutter.org/gems/local_cache>.
You can also use memcached or http://www.quetzall.com/cloudcache.

## Encryption

SimpleRecord has built in support for encrypting attributes with AES-256 encryption and one way hashing using SHA-512 (good for passwords).  And it's easy to use.

Here is an example of a model with an encrypted attribute and a hashed attribute.

    class ModelWithEnc < SimpleRecord::Base
        has_strings :name,
                    {:name=>:ssn, :encrypted=>"simple_record_test_key"},
                    {:name=>:password, :hashed=>true}
    end

The :encrypted option takes a key that you specify. The attribute can only be decrypted with the exact same key.

The :hashed option is simply true/false.

Encryption is generally transparent to you, SimpleRecord will store the encrypted value in the database and unencrypt it when you use it.

Hashing is not quite as transparent as it cannot be converted back to it's original value, but you can do easy comparisons with it, for instance:

ob2.password == "mypassword"

This will actually be compared by hashing "mypassword" first.

## Sharding

Sharding allows you to partition your data for a single class across multiple domains allowing increased write throughput,
faster queries and more space (multiply your 10GB per domain limit).  And it's very easy to implement with SimpleRecord.

    shard :shards=>:my_shards_function, :map=>:my_mapping_function

The :shards function should return a list of shard names, for example: ['CA', 'FL', 'HI', ...] or [1,2,3,4,...]

The :map function should return which shard name the object should be stored to.

When executing a find() operation, you can explicitly specify the shard(s) you'd like to find on. This is
particularly useful if you know in advance which shard the data will be in.

    MyShardedClass.find(:all, :conditions=>....., :shard=>["CA", "FL"])

You can see some [example classes here](https://github.com/appoxy/simple_record/blob/master/test/my_sharded_model.rb).

## Concurrency

**Subject to change**

This was brought on as a way to query across shards in parallel. Not being able to find a good generic concurrency library,
I ended up rolling my own called [concur](https://github.com/appoxy/concur).

    MyShardedClass.find(:all, :concurrent=>true)

We may enable a global [Executor](https://github.com/appoxy/concur/blob/master/lib/executor.rb) so you can have a fixed
thread pool across your app, but for now, it will fire up a thread per shard. 

## Kudos

Special thanks to Garrett Cox for creating Activerecord2sdb which SimpleRecord is based on:
http://activrecord2sdb.rubyforge.org/

## License

SimpleRecord is released under the MIT License.
