
require "core/agent"

------------------------------------------------------------------------------
--DER speculator definition
------------------------------------------------------------------------------

DERspeculator = MinimalAgent:new{
	agentID = 0,
	agentType = "DERspeculator",
	inventory = {},
	money = 40,
	profit = 0.0,
	population = nil,
	clearingHouse = nil,
	margin = 0.1
}

function DERspeculator:new( o )
	o = o or {}
	setmetatable( o, self )
	self.__index = self
	
	--inventory related construction
	o.inventory = Inventory:new{
		stock = 
		{
			wood = math.random(0,50),
			tools = math.random(0,50),
			ore = math.random(0,50),
			metal = math.random(0,50),
			food = math.random(0,50)
		},
		limit = 
		{
			wood = 50,
			tools = 50,
			ore = 50,
			metal = 50,
			food = 50
		}
	}
	o.inventory:setInventory( "food", math.random(0, 50) )
	o.inventory:setInventory( "wood", math.random(0, 50) )
	o.inventory:setInventory( "ore", math.random(0, 50) )
	o.inventory:setInventory( "metal", math.random(0, 50) )
	o.inventory:setInventory( "tools", math.random(0, 50) )
	
	return o
end

function DERspeculator:performProduction()
	self.profit = 0.0
	for c in pairs( self.clearingHouse:getCommodities() ) do
		local d = self:getSecondPriceDerivative( c )
		--if d < 0, price curve is decreasing: SELL
		--if d > 0, price curve is increasing: BUY
		if d < 0 then
			self:createAsk( c )
		else
			self:createBid( c )
		end
	end
end

function DERspeculator:getSecondPriceDerivative( c )
	local p = self.clearingHouse:getHistory( c )
	if not p then
		--returning 0 will cause the speculator to do nothing.
		return 0
	end
	return p[1] - 2 * p[2] + p[3]
end

function DERspeculator:createBid( c )
	local p = self.clearingHouse:getCommodityMean( c )
	local up = p * ( 1 + self.margin )
	local amount = self.inventory:getSpace( c )
	self.clearingHouse:postBid( Offer:new{ 
			agentID = self.agentID,
			commodity = c,
			quantity = amount, 
			unitPrice = up 
	} )
end

function DERspeculator:createAsk( c )
	local p = self.clearingHouse:getCommodityMean( c )
	local up = p * ( 1 + self.margin )
	local amount = self.inventory:getSpace( c )
	self.clearingHouse:postBid( Offer:new{ 
			agentID = self.agentID,
			commodity = c,
			quantity = amount, 
			unitPrice = up 
	} )
end

function DERspeculator:acceptAsk( c, value )
	--@profit += value
	self.profit = self.profit + value
end

function DERspeculator:acceptBid( c, value )
	self.profit = self.profit - value
end

------------------------------------------------------------------------------
--AVG speculator definition
------------------------------------------------------------------------------

AVGspeculator = MinimalAgent:new{
	agentID = 0,
	agentType = "AVGspeculator",
	inventory = {},
	money = 40,
	profit = 0.0,
	population = nil,
	clearingHouse = nil,
	margin = 0.1,
	old_p = 0,
	beta = 0.8
}

function AVGspeculator:new( o )
	o = o or {}
	setmetatable( o, self )
	self.__index = self
	
	--inventory related construction
	o.inventory = Inventory:new{
		stock = 
		{
			wood = math.random(0,50),
			tools = math.random(0,50),
			ore = math.random(0,50),
			metal = math.random(0,50),
			food = math.random(0,50)
		},
		limit = 
		{
			wood = 50,
			tools = 50,
			ore = 50,
			metal = 50,
			food = 50
		}
	}
	o.inventory:setInventory( "food", math.random(0, 50) )
	o.inventory:setInventory( "wood", math.random(0, 50) )
	o.inventory:setInventory( "ore", math.random(0, 50) )
	o.inventory:setInventory( "metal", math.random(0, 50) )
	o.inventory:setInventory( "tools", math.random(0, 50) )
	
	return o
end

function AVGspeculator:performProduction()
	self.profit = 0.0
	for c in pairs( self.clearingHouse:getCommodities() ) do
		local pred = self:getPriceForecast( c )
		local p = self.clearingHouse:getCommodityMean( c )
		--if ^p ( 1 - margin ) > p[1] then BUY 
		--if ^p ( 1 + margin ) > p[1] then SELL
		if pred * ( 1 - self.margin ) > p then
			self:createBid( c )
		elseif pred * ( 1 + self.margin ) < p then
			self:createAsk( c )
		end
	end
end

function AVGspeculator:getPriceForecast( c )
	local p = self.clearingHouse:getHistory( c )
	if not p then
		--this is an error code, performProduction will do nothing
		return -1
	end
	if self.old_p == 0 then
		self.old_p = p[1]
	end
	
	local result = self.beta * self.old_p + ( 1 - self.beta ) * p[2]
	self.old_p = result
	return result
end

AVGspeculator.createBid = DERspeculator.createBid

AVGspeculator.createAsk = DERspeculator.createAsk

function AVGspeculator:acceptBid( c, value )
	self.profit = self.profit - value
end

function AVGspeculator:acceptAsk( c, value )
	self.profit = self.profit + value
end


