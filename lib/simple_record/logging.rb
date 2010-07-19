module SimpleRecord

    require 'csv'

    module Logging


        module ClassMethods
            def write_usage(type, domain, q_type, params, results)
                #puts 'params=' + params.inspect
                #puts 'logging_options=' + SimpleRecord.usage_logging_options.inspect
                if SimpleRecord.usage_logging_options
                    type_options = SimpleRecord.usage_logging_options[type]
                    if type_options
                        file = type_options[:file]
                        if file.nil?
                            file = File.open(type_options[:filename], File.exists?(type_options[:filename]) ? "a" : "w")
                            puts file.path
                            type_options[:file] = file
                        end
                        conditions = params[:conditions][0] if params[:conditions]
                        line = usage_line(type_options[:format], [type, domain, q_type, conditions, params[:order]], results[:request_id], results[:box_usage])
                        file.puts line
                        type_options[:lines] = type_options[:lines] ? type_options[:lines] + 1 : 1
                        #puts 'lines=' + type_options[:lines].to_s
                        if type_options[:lines] % type_options[:lines_between_flushes] == 0
                            #puts "flushing to file..."
                            file.flush
#                            sleep 20
                        end
#                        puts 'line=' + line
                    end
                end
            end

            def usage_line(format, query_data, request_id, box_usage)
                if format == :csv
                    line_data = []
                    line_data << Time.now.iso8601
                    query_data.each do |r|
                        line_data << r.to_s
                    end
                    line_data << request_id
                    line_data << box_usage
                    return CSV.generate_line(line_data)
                end
            end
        end
    end
end

