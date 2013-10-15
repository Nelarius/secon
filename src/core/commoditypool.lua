
CommodityPool = { pool = {}, price = {} }

function CommodityPool:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

--returns a table where each key is a commodity and the value is the count
function CommodityPool:getCommodities()
	return self.pool
end

function CommodityPool:getCommodity( c, amount )
	return self:__getFinCommodity( c, amount )
end

function CommodityPool:setCommodityPool( pTable )
	self.pool = pTable
end

function CommodityPool:setCommodityPrice( pTable )
	self.price = pTable
end

function CommodityPool:setCommodityMean( c, value )
	self.price[c] = value
end

function CommodityPool:getCommodityMean( c )
	return self.price[c]
end

function CommodityPool:getCommodityPriceTable()
	return self.price
end


------------------------------------------------------------------------------
--two different kinds of getCommodity
------------------------------------------------------------------------------

--infinite source
function CommodityPool:__getInfCommodity( c, amount )
	return amount
end

--finite source
function CommodityPool:__getFinCommodity( c, amount )
	local result
	if self.pool[c] < amount then
		result = self.pool[c]
		self.pool[c] = 0
	else
		result = amount
		self.pool[c] = self.pool[c] - amount
	end
	return result
end
