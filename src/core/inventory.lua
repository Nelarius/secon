
--[[
	This class represents an stock, in which commodities are stored associatively
	with their supply (integers). Same goes for the stock limits. Use-case:
	
	inv = Inventory:new{ stock = { wood = 10 }, limit = { wood = 20 } }
	
	inv:setLimit()
]]
Inventory = { stock = {}, limit = {} }

function Inventory:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

--[[
	Subtract a positive value of commodity c from stock. The function returns
	the actual amount subtracted. You can subtract more than what the actual supply
	is, and the stock will go to zero. The function returns the amount actually
	subtracted.
]]
function Inventory:subtractFromInventory( c, amount, id )
	if amount < 0 then
		return
	end
	local result
	if amount > self.stock[c] then
		result = self.stock[c]
		self.stock[c] = 0
	else
		self.stock[c] = self.stock[c] - amount
		result = amount
	end
	return result
end

function Inventory:depositToInventory( c, amount, id )
	
	if amount < 0 then
		return
	end
	self.stock[c] = self.stock[c] + amount
	if self.stock[c] > self.limit[c] then
		self.stock[c] = self.limit[c]
	end
end

function Inventory:getInventory( c )
	return self.stock[c]
end

function Inventory:setInventory( c, value )
	if value < 0 then
		print("function Inventory:setInventory : value negative" )
	end
	assert( value >= 0)
	
	if value > self.limit[c] then
		self.stock[c] = self.limit[c]
	else
		self.stock[c] = value
	end
end

function Inventory:getLimit( c )
	return self.limit[c]
end

function Inventory:setLimit( c, value )
	if value < 0 then
		print( "function Inventory:setLimit : value negative")
	end
	assert( value > 0 )
	
	if self.stock[c] > value then
		self.stock[c] = value
	end
	
	self.limit[c] = value
end

