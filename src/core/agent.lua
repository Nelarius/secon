
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
			beliefIsUpdated = {},
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
__SD_IMBALANCE = 0.5

--[[
	For deciding when to make drastic price belief updates. The value represents the
	ratio of inventory over the threshold, and the range between the threshold and 
	respective limit.
]]
__INVENTORY_IMBALANCE = 0.5

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
	for c in pairs( self.beliefIsUpdated ) do
		self.beliefIsUpdated[ c ] = false
	end
	
	for _, rule in ipairs( self.productionRules ) do
		rule( self )	--call each rule
	end
end

function Agent:finally()
	local tabl = self.clearingHouse:getCommodities()
	for c in pairs( tabl ) do
		self:anticipateSupplyDemandChange( c )
	end
end

function Agent:addProductionRule( rule )
	table.insert( self.productionRules, rule )
end

function Agent:checkAcquisitions(...)
	for _, c in ipairs( arg ) do
		if self.inventory:getInventory( c ) <= self.commodityAcquireThreshold[c] then
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
	
	local excess = self.inventory:getInventory( c ) - self.commoditySellThreshold[c]
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
	
	local space = self.inventory:getLimit( c ) - self.inventory:getInventory( c )
	--local space = self.inventoryLimit[c] - self.inventory[c]
	return math.floor( favorability * space )
end

function Agent:createBid( c )
	local toAcquire = self:determinePurchaseQuantity( c )
	
	local uPrice = self.priceBelief[c]:getRandomValue()

	--print("createBid: mean = "..self.priceBelief[c]:getMean()..", range = "..self.priceBelief[c]:getRange()..", uPrice = "..uPrice )
	--print(self.priceBelief[c]:getMean())
	--assert( self.priceBelief[c]:getMean() >= 0)
	--assert( uPrice > 0 )
	
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
	

	--print("createAsk: mean = "..self.priceBelief[c]:getMean()..", range = "..self.priceBelief[c]:getRange()..", uPrice = "..uPrice )

	--assert( self.priceBelief[c]:getMean() >= 0)
	--assert( uPrice > 0 )
	
	self.clearingHouse:postAsk( Offer:new{ agentID = self.agentID, commodity = c,
											quantity = toSell, unitPrice = uPrice } )
end

function Agent:observeTrade( c, value )
	if table.empty( self.observedTrades[c] ) then
		self.observedTrades[c] = FifoQ:new()
	end
	self.observedTrades[c]:enqueue( value )
end

-- delta > 0 : belief mean is lower than global mean
-- delta < 0 : belief mean is higher than global mean
function Agent:getBeliefUpdateData( c )
	local mean = self.clearingHouse:getCommodityMean( c )
	local delta = mean - self.priceBelief[c]:getMean()
	local range = 0.5 * ( self.priceBelief[c]:getRange() )
	return mean, delta, range
end

function Agent:acceptBid( c, value )
	self.beliefIsUpdated[c] = true
	self:observeTrade( c, value )
	local mean, delta, range = self:getBeliefUpdateData( c )
	--reinforce belief
	--move bounds inward by 5% of the range
	--local amount = 1 - 0.1 * self.priceBelief[c]:getMean() / self.priceBelief[c]:getRange()
	self.priceBelief[c]:scaleRange( 0.95 )
	
	if delta < 0 and range / delta > -__SIGNIFICANT then	--significantly overpaid
		self.priceBelief[c]:translateRange( 0.25 * delta )
	end
end

function Agent:acceptAsk( c, value )
	self.beliefIsUpdated[c] = true
	self:observeTrade( c, value )
	local mean, delta, range = self:getBeliefUpdateData( c )
	--reinforce belief
	--move bounds inward by 5% of the range
	--local amount = 1 - 0.1 * self.priceBelief[c]:getMean() / self.priceBelief[c]:getRange()
	--print("mean = "..self.priceBelief[c]:getMean()..", range = "..self.priceBelief[c]:getRange() )
	self.priceBelief[c]:scaleRange( 0.95 )
	
	if delta > 0 and range / delta < __SIGNIFICANT then	--significantly undersold
		self.priceBelief[c]:translateRange( 0.25 * delta )
	end
end

function Agent:rejectAsk( c )
	self.beliefIsUpdated[c] = true
	local mean, delta, range = self:getBeliefUpdateData( c )
	--increase uncertainty in price belief
	--local amount = 1 + 0.05 * self.priceBelief[c]:getMean() / self.priceBelief[c]:getRange()
	self.priceBelief[c]:scaleRange( 1.05 )
	
	--check for nearly full inventory
	local overThr = self.inventory:getInventory( c ) - self.commoditySellThreshold[c]
	--local overThr = self.inventory[c] - self.commoditySellThreshold[c]
	
	if self.inventory:getInventory( c ) < self.commoditySellThreshold[c] then
		print("inventory for "..c.." is "..self.inventory:getInventory( c ).." with threshold "..self.commoditySellThreshold[c] )
	end
	assert( self.inventory:getInventory( c ) >= self.commoditySellThreshold[c] )
	local limitThrRange = self.inventory:getLimit( c ) - self.commoditySellThreshold[c]
	if overThr / limitThrRange > __INVENTORY_IMBALANCE then
		--go under the global mean to ensure selling success
		self.priceBelief[c]:translateRange( 1.2 * delta )
	end
end

function Agent:rejectBid( c )
	self.beliefIsUpdated[c] = true
	local mean, delta, range = self:getBeliefUpdateData( c )
	--increase uncertainty in price belief
	--local amount = 1 + 0.05 * self.priceBelief[c]:getMean() / self.priceBelief[c]:getRange()
	self.priceBelief[c]:scaleRange( 1.05 )
	
	--check for nearly empty inventory
	if self.inventory:getInventory( c ) / self.commodityAcquireThreshold[c] < __INVENTORY_IMBALANCE then
		--go over the global mean to ensure bidding success
		self.priceBelief[c]:translateRange( 1.2 * delta )
	end
end

function Agent:anticipateSupplyDemandChange( c )
	local temp = self.priceBelief[c]:getMean()
	if not self.beliefIsUpdated[c] then
		local ratio = self.clearingHouse:getSupplyDemandRatio( c )
		if ratio > __SD_IMBALANCE or ratio < - __SD_IMBALANCE then
			--if there is an imbalance, then bid for a higher or lower price then the
			--current global mean
			local newMean = ( 1 - ratio ) * self.clearingHouse:getCommodityMean( c )
			local delta = newMean - self.priceBelief[c]:getMean()
			--scale the delta slightly to prevent drastic shifts in price belief
			self.priceBelief[c]:translateRange( 0.5 * delta )
		end
	end
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
	return self.inventory:subtractFromInventory( c, amount )
end

function Agent:depositToInventory( c, amount )
	self.inventory:depositToInventory( c, amount )
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
	local amount = self.inventory:getInventory( c )
	return self:consume( c, amount )
end

function Agent:getAgentType()
	return self.agentType
end

function Agent:getProfit()
	return self.profit
end

