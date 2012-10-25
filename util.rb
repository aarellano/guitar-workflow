class ETR

@@start_time = Time.now
@@current_cycle = 0
@@cycles = 0

def self.start cycles
	@@start_time = Time.now
	@@cycles = cycles
end

def self.run
	return nil if (@@current_cycle += 1) > @@cycles
	average = (Time.now - @@start_time) / @@current_cycle
	time_remaining = (@@cycles - @@current_cycle) * average
end

def self.finish
	Time.now - @@start_time
end

end