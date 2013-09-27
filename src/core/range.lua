
require "core/enum"

RangeState = enum{ "Clamped", "Unclamped" }

Range = {
			mean = 2.0,
			range = 1.0,
			state = RangeState[ "Unclamped" ]
		}

function Range:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

function Range:getMean()
	return self.mean
end

function Range:getMin()
	if self.state == RangeState[ "Clamped" ] then
		return 0
	else
		return self.mean - 0.5 * self.range
	end
end

function Range:getMax()
	return self.mean + 0.5 * self.range
end

function Range:getRange()
	return self.range
end

--[[
	Scale the range by the value amount. If the range were to go into a negative value, then the
	range will be clamped to the value which gives a zero minimum.
]]
function Range:scaleRange( amount )
	--prevent the range from diminishing into nothing
	if self.range < 0.1 then
		return
	end
	
	assert( amount > 0 )
	
	self.range = self.range * amount
	
	if self.mean - 0.5 * self.range < 0 then
		self.state = RangeState[ "Clamped" ]
	else
		self.state = RangeState[ "Unclamped" ]
	end
end

--[[
	Translate the range (mean) by a positive or negative amount. If the range were to go into a negative
	value as a result of this translation, the translation will be clamped to the value which gives a
	zero minimum.
]]
function Range:translateRange( amount )
	if self.mean + amount <= 0 then
		self.state = RangeState[ "Clamped" ]
		self.mean = 0.1
		return
	end
	
	self.mean = self.mean + amount
	
	if self.mean - 0.5 * self.range < 0 then
		self.state = RangeState[ "Clamped" ]
	else
		self.state = RangeState[ "Unclamped" ]
	end
end

function Range:getRandomValue()
	if self.state == RangeState[ "Unclamped" ] then
		return self.mean + ( 0.5 - math.random() ) * self.range
	else
		--avoid returning zero
		return ( math.random() + 0.002 ) * self.range
	end
end
