class TestHelpers

  def self.clear_out_my_models
    mms = MyModel.find(:all)
    puts 'mms.size=' + mms.size.to_s
    i = 0
    mms.each do |x|
      puts 'deleting=' + i.to_s
      x.delete
      i+=1
    end
  end

end