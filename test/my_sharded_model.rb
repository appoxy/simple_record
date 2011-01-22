require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")

require File.expand_path(File.dirname(__FILE__) + "/../lib/simple_record")

class MyShardedModel < SimpleRecord::Base

  shard :shards=>:my_shards, :map=>:my_mapping_function

  has_strings :name

  def self.num_shards
    4
  end

  def self.my_shards
    Array(0...self.num_shards)
  end

  def my_mapping_function
    shard_num = SimpleRecord::Sharding::Hashing.sdbm_hash(self.id) % self.class.num_shards
    puts "shard_num=" + shard_num.inspect
    shard_num
  end

  def self.shard_for_find(id)
    shard_num = SimpleRecord::Sharding::Hashing.sdbm_hash(id) % self.num_shards
  end

end


class MyShardedByFieldModel < SimpleRecord::Base

  shard :shards=>:my_shards, :map=>:my_mapping_function

  has_strings :name, :state

  def self.my_shards
    ['AL', 'CA', 'FL', 'NY']
  end

  def my_mapping_function
    state
  end

end
