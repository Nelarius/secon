
require "core/offer"
require "core/utils"
require "core/fifoq"
require "core/clearinghouse"

Agent = {
			agentID = 0,
			agentType = "",
			priceBelief = {},
			observedTrades = {},
			inventory = {},
			commoditySellThreshold = {},
			commodityAcquireThreshold = {},
			inventoryLimit = {},
			money = 0.0,
			profit = 0.0,
			moneyBidded = 0.0,	--used for making sure the agent does not bid for more than it can spend
			owner = nil,	--is this variable needed?
			population = nil,
			clearingHouse = nil,
			productionRules = {}
		}
		

--[[
	What percentage of the price belief range the delta between mean and actual mean (last round) should
	be in order to incur a price belief translation.
]]
__SIGNIFICANT = 0.4

--[[
	For anticipating supply & demand imbalance
]]
__SD_IMBALANCE = 0.2

--[[
	For deciding when to make drastic price belief updates.
]]
__INVENTORY_IMBALANCE = 0.1

function Agent:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

function Agent:getExpenditure()
	--abstract method which will have to be implemented
	return -1
end

function Agent:performProduction()
	self.profit = 0.0	--reset the profit accumulator
	self.moneyBidded = 0.0
	
	for _, rule in ipairs( self.productionRules ) do
		rule( self )	--call each rule
	end
end

function Agent:addProductionRule( rule )
	table.insert( self.productionRules, rule )
end

function Agent:checkAcquisitions(...)
	for _, c in ipairs( arg ) do
		if self.inventory[c] <= self.commodityAcquireThreshold[c] then
			self:createBid( c )
		end
	end
end

function Agent:determineSaleQuantity( c )
	local mean = self.clearingHouse:getCommodityMean( c )
	local favorability = 1.0
	--if there are observed trades, then calculate favorability < 1.0 to possibly save money
	
	if not table.empty( self.observedTrades[c] ) then
		local observedMean = self.observedTrades[c]:getMean()
		if mean - observedMean < 0 then
			local position = observedMean - mean	--make sure agent is not underselling
			local range = 0.5 * (self.observedTrades[c]:getMax() - self.observedTrades[c]:getMin())
			favorability = math.min( 1.0, range / position )
		end
	end
	
	local excess = self.inventory[c] - self.commoditySellThreshold[c]
	return math.ceil( favorability * excess )
end

function Agent:determinePurchaseQuantity( c )
	local mean = self.clearingHouse:getCommodityMean( c )
	local favorability = 1.0
	
	if not table.empty( self.observedTrades[c] ) then
		local observedMean = self.observedTrades[c]:getMean()
		if mean - observedMean > 0 then
			local position = mean - observedMean	--make sure agent won't bid too much
			local range = 0.5 * ( self.observedTrades[c]:getMax() - self.observedTrades[c]:getMin() )
			favorability = math.min( 1.0, range / position )
		end
	end
	
	local space = self.inventoryLimit[c] - self.inventory[c]
	return math.floor( favorability * space )
end

function Agent:createBid( c )
	local toAcquire = self:determinePurchaseQuantity( c )
	--determine random number in price belief range
	local uPrice = self.priceBelief[c]:getRandomValue()
	
	assert( self.priceBelief[c]:getMin() >= 0)
	assert( self.priceBelief[c]:getMean() >= 0)
	assert( uPrice > 0)
	
	--check that we are not bidding for more than we can pay (based on money possessed currently)
	if uPrice * toAcquire + self.moneyBidded > self.money and self.moneyBidded < self.money then
		local delta = self.money - self.moneyBidded
		toAcquire = math.floor( delta / uPrice )
	elseif self.moneyBidded > self.money then	--can't afford to pay next turn, so skip
		return
	end
	
	if toAcquire > 0 then
		self.clearingHouse:postBid( Offer:new{  agentID = self.agentID, commodity = c,
												quantity = toAcquire, unitPrice = uPrice } )
												
		self.moneyBidded = self.moneyBidded + uPrice * toAcquire
	end
end

function Agent:createAsk( c )
	local toSell = self:determineSaleQuantity( c )
	
	local uPrice = self.priceBelief[c]:getRandomValue()
	
	assert( self.priceBelief[c]:getMin() >= 0)
	assert( self.priceBelief[c]:getMean() >= 0)
	assert( uPrice > 0 )
	
	self.clearingHouse:postAsk( Offer:new{ agentID = self.agentID, commodity = c,
											quantity = toSell, unitPrice = uPrice })
end

function Agent:observeTrade( c, value )
	if table.empty( self.observedTrades[c] ) then
		self.observedTrades[c] = FifoQ:new()
	end
	self.observedTrades[c]:enqueue( value )
end

function Agent:getBeliefUpdateData( c )
	local mean = self.clearingHouse:getCommodityMean( c )
	local delta = mean - self.priceBelief[c]:getMean()
	local range = 0.5 * ( self.priceBelief[c]:getRange() )
	return mean, delta, range
end

function Agent:acceptBid( c, value )
	self:observeTrade( c, value )
	local mean, delta, range = self:getBeliefUpdateData( c )
	--reinforce belief
	--move bounds inward by 5% of the mean
	local amount = 1 - 0.1 * self.priceBelief[c]:getMean() / self.priceBelief[c]:getRange()
	assert( amount > 0 )
	self.priceBelief[c]:scaleRange( amount )
	
	if delta < 0 and range / delta > -__SIGNIFICANT then	--significantly overpaid
		self.priceBelief[c]:translateRange( 0.25 * delta )
	end
end

function Agent:acceptAsk( c, value )
	self:observeTrade( c, value )
	local mean, delta, range = self:getBeliefUpdateData( c )
	--reinforce belief
	--move bounds inward by 5% of the mean
	local amount = 1 - 0.1 * self.priceBelief[c]:getMean() / self.priceBelief[c]:getRange()
	print("mean = "..self.priceBelief[c]:getMean()..", range = "..self.priceBelief[c]:getRange() )
	assert( amount > 0 )
	self.priceBelief[c]:scaleRange( amount )
	
	if delta > 0 and range / delta < __SIGNIFICANT then	--significantly undersold
		self.priceBelief[c]:translateRange( 0.25 * delta )
	end
end

function Agent:rejectAsk( c )
	local mean, delta, range = self:getBeliefUpdateData( c )
	--increase uncertainty in price belief
	--move bounds outward by 5% of the mean
	local amount = 1 + 0.05 * self.priceBelief[c]:getMean() / self.priceBelief[c]:getRange()
	self.priceBelief[c]:scaleRange( amount )
end

function Agent:rejectBid( c )
	local mean, delta, range = self:getBeliefUpdateData( c )
	--increase uncertainty in price belief
	local amount = 1 + 0.05 * self.priceBelief[c]:getMean() / self.priceBelief[c]:getRange()
	self.priceBelief[c]:scaleRange( amount )
end

function Agent:subtractMoney( amount )
	local result
	if amount > self.money then
		result = self.money
		self.money = 0.0
		self:declareBankruptcy()
	else
		self.money = self.money - amount
		result = amount
	end
	self.profit = self.profit - result
	return result
end

function Agent:depositMoney( amount )
	self.money = self.money + amount
	self.profit = self.profit + amount
end

function Agent:subtractFromInventory( c, amount )
	local result
	if amount > self.inventory[c] then
		result = self.inventory[c]
		self.inventory[c] = 0
	else
		self.inventory[c] = self.inventory[c] - amount
		result = amount
	end
	return result
end

function Agent:depositToInventory( c, amount )
	self.inventory[c] = self.inventory[c] + amount
end

function Agent:declareBankruptcy()
	self.population:flagBankruptcy( self.agentID )
end

function Agent:produce( c, amount )
	self:depositToInventory( c, amount )
end

function Agent:consume( c, amount )
	return self:subtractFromInventory( c, amount )
end

function Agent:consumeAll( c )
	local amount = self.inventory[c]
	return self:consume( c, amount )
end

function Agent:getAgentType()
	return self.agentType
end

function Agent:getProfit()
	return self.profit
end

