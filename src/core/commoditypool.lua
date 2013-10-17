
CommodityPool = { pool = {}, price = {}, history = {} }

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

function CommodityPool:fetchCommodity( c, amount )
	return self:__getInfCommodity( c, amount )
end

function CommodityPool:setCommodityPool( pTable )
	self.pool = pTable
end

function CommodityPool:setCommodityPrice( pTable )
	self.price = pTable
end

function CommodityPool:setCommodityMean( c, value )
	self.price[c] = value
	
	--log the value in the price history
	if table.empty( self.history[c] ) then
		--create a new queue with a max length 3.
		self.history[c] = FifoQ:new{
			head = nil,
			tail = nil,
			limit = 3,
			count = 0,
			max = -1,
			min = -1
		}
	end
	self.history[c]:enqueue( value )
end

function CommodityPool:getHistory( c )
	if table.empty( self.history[c] ) or self.history[c]:getLength() < 3 then
		return nil
	end
	return self.history[c]:getValues()
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
