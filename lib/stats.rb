module SimpleRecord
    class Stats
        attr_accessor :selects, :puts

        def initialize
            @selects = 0
            @puts = 0
        end

        def clear
            self.selects = 0
            self.puts = 0
        end
    end
end

