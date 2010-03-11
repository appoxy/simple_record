# This will help setup for easier setup in Rails apps.

puts 'SimpleRecord rails/init.rb...'
SimpleRecord.options[:connection_mode] = :per_thread

::ApplicationController.class_eval do
    def close_sdb_connection
        puts "Closing sdb connection."
        SimpleRecord.close_connection
    end
end
::ApplicationController.send :after_filter, :close_sdb_connection
