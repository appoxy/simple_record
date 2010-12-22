module SimpleRecord
    class Stats
        attr_accessor :selects, :saves, :deletes, :s3_puts, :s3_gets, :s3_deletes

        def initialize
            @selects = 0
            @saves = 0
            @deletes = 0
            @s3_puts = 0
            @s3_gets = 0
            @s3_deletes = 0
        end

        def clear
            self.selects = 0
            self.saves = 0
            self.deletes = 0
            self.s3_puts = 0
            self.s3_gets = 0
            self.s3_deletes = 0
        end
    end
end

