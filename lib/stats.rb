module SimpleRecord
    class Stats
        attr_accessor :selects, :puts

        def clear
            self.selects = 0
            self.puts = 0
        end
    end
end