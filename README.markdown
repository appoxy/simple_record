# simple_record

http://code.google.com/p/simple-record/

## DESCRIPTION:

An ActiveRecord interface for SimpleDB.  Can be used as a drop in replacement for ActiveRecord in rails.

Special thanks to Garrett Cox for creating Activerecord2sdb which SimpleRecord is based on: 
http://activrecord2sdb.rubyforge.org/

## Getting Started

1. Install gems

        gem install appoxy-aws uuidtools appoxy-simple_record

2. Create a model

        require 'simple_record'
    
        class MyModel < SimpleRecord::Base
           has_attributes :name
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


## Attributes and modifiers for models

NOTE: All objects will automatically have :id, :created, :updated attributes.

### has_attributes

Add string attributes.

    class MyModel
      has_attributes :name
    end

### has_ints, has_dates and has_booleans

Lets simple_record know that certain attributes defined in has_attributes should be treated as integers, dates or booleans. This is required because SimpleDB only has strings so SimpleRecord needs to know how to convert, pad, offset, etc.

    class MyModel
      has_attributes :name
      has_ints :age, :height
      has_dates :birthday
      has_booleans :is_nerd
    end

### belongs_to

Creates a many-to-one relationship. Can only have one per belongs_to call.

    class MyModel
        belongs_to :school
        has_attributes :name
        has_ints :age, :height
        has_dates :birthday
        has_booleans :is_nerd
    end

Which requires another class called 'School' or you can specify the class explicitly with:

    belongs_to :school, :class_name => "Institution"

### set_table_name or set_domain_name

If you want to use a custom domain for a model object, you can specify it with set_table_name (or set_domain_name).

    class SomeModel
        set_table_name :different_model
    end


## Configuration

### Domain Prefix

To set a global prefix across all your models, use:

    SimpleRecord::Base.set_domain_prefix("myprefix_")

### Connection Modes

There are 4 different connection modes:

* per_request (default) - opens and closes a new connection to simpledb for every simpledb request. Not the best performance, but it's safe and can handle many concurrent requests at the same time (unlike single mode).
* single - one connection across the entire application, not recommended unless the app is used by a single person.
* per_thread - a connection is used for every thread in the application. This is good, but the catch is that you have to ensure to close the connection.
* pool - NOT IMPLEMENTED YET - opens a maximum number of connections and round robins them for any simpledb request.

You set the mode when you call establish_connection:

    SimpleRecord.establish_connection(AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY, :connection_mode=>:per_thread)

We recommend per_thread with explicitly closing the connection after each Rails request (not to be mistaken for a SimpleDB request) or pool for rails apps.

For rails, be sure to add this to your Application controller if using per_thread mode:

    after_filter :close_sdb_connection

    def close_sdb_connection
        SimpleRecord.close_connection
    end

## SimpleRecord on Rails

You don't really have to do anything except have your models extends SimpleRecord::Base instead of ActiveRecord::Base, but here are some tips you can use.

### Change Connection Mode

Use per_thread connection mode and close the connection after each request.

    after_filter :close_sdb_connection

      def close_sdb_connection
        SimpleRecord.close_connection
      end

### Disable ActiveRecord so you don't have to setup another database

This is most helpful on windows so Rails doesn't need sqlite or mysql gems/drivers installed which are painful to install on windows. In environment.rb, add 'config.frameworks -= [ :active_record ]', should look something like:

    Rails::Initializer.run do |config|
      config.frameworks -= [ :active_record ]
      ....
    end


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

