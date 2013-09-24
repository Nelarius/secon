
require "core/zone"

Economy = {
			zone = TestZone:new()
			}

function Economy:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self	
	return object
end

function Economy:update()
	self.zone:update()
end

function Economy:run( times )
	self.zone:initialize()
	for i = 1, times, 1 do
		self:update()
	end
end