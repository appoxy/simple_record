require File.expand_path(File.dirname(__FILE__) + "/../../lib/simple_record")
require_relative 'my_base_model'
require_relative 'my_sharded_model'
require 'active_model'

class MyModel < MyBaseModel

  has_strings :name, :nickname, :s1, :s2
  has_ints :age, :save_count
  has_booleans :cool
  has_dates :birthday, :date1, :date2, :date3

#    validates_presence_of :name


#  validate :validate
#  before_create :validate_on_create
#  before_update :validate_on_update

  validates_uniqueness_of :name

  belongs_to :my_sharded_model

  has_clobs :clob1, :clob2

  attr_accessor :attr_before_save, :attr_after_save, :attr_before_create, :attr_after_create, :attr_after_update

  #callbacks
  before_create :set_nickname
  after_create :after_create

  before_save :before_save

  after_save :after_save
  after_update :after_update

  def set_nickname
    @attr_before_create = true
    self.nickname = name if self.nickname.blank?
  end

  def before_save
    @attr_before_save = true
  end

  def after_create
    @attr_after_create = true
  end
  
  def after_save
    @attr_after_save = true
    bump_save_count
  end
    def after_update
    @attr_after_update = true
  end

  def bump_save_count
    if save_count.nil?
      self.save_count = 1
    else
      self.save_count += 1
    end
  end

  def validate
    errors.add("name", "can't be empty.") if name.blank?
  end

  def validate_on_create
    errors.add("save_count", "should be zero.") if !save_count.blank? && save_count > 0
  end

  def validate_on_update
  end

  def atts
    @@attributes
  end


end


class SingleClobClass < SimpleRecord::Base

  sr_config :single_clob=>true

  has_strings :name

  has_clobs :clob1, :clob2
end
