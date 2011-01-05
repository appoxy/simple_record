require_relative 'my_model'


begin
  raise StandardError
rescue => ex
  p ex
  puts ex.message
end
