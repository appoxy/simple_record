
require File.expand_path(File.dirname(__FILE__) + "/../lib/results_array")

array = SimpleRecord::ResultsArray.new()
#array.extend(ResultsArray)

500.times do |i|
    array << "_ob_" + i.to_s
end

array.each do |v|
    puts v.to_s
end

puts array[10]