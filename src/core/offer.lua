
--[[
	Document string
]]

Offer = {
			agentID = 0,
			commodity = "",
			quantity = 0,
			unitPrice = 0.0
		}
		
function Offer:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end


--[[
	Function corresponding to the '<' operator.
]]
function Offer.__lt( o1, o2 )
	return o1.unitPrice < o2.unitPrice
end


--[[
	Function corresponding to the '>' operator.
]]
function Offer.gt( o1, o2 )
	return o1.unitPrice > o2.unitPrice
end
