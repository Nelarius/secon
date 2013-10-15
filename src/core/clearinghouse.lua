
require "core/offer"

ClearingHouse = {
					bidBook = {},	--an array of offers for each commodity
					askBook = {},	--an array of offers for each commodity
					sdLogger = LoggerLocator.getLogger( "core/supplydemand.dat" ),
					priceLogger = LoggerLocator.getLogger( "core/price.dat" ),
					tradeVolumeLogger = LoggerLocator.getLogger( "core/tradevolume.dat" ),
					bidVolumeLogger = LoggerLocator.getLogger( "core/bidvolume.dat" ),
					askVolumeLogger = LoggerLocator.getLogger( "core/askvolume.dat" ),
					commodityPool = {},
					sdRatio = {},
					owner = nil
				}

function ClearingHouse:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

function ClearingHouse:postBid( offer )
	local c = offer.commodity
	if table.empty( self.bidBook[c] ) then
		self.bidBook[c] = {}
	end
	table.insert( self.bidBook[c], offer )
end

function ClearingHouse:postAsk( offer )
	local c = offer.commodity
	if table.empty( self.askBook[c] ) then
		self.askBook[c] = {}
	end
	table.insert( self.askBook[c], offer )
end

--offer resolution using a double auction
function ClearingHouse:resolveOffers()
	--for calculating prices
	local tradeAverage = {}
	local tradeVolume = {}
	local bidAverage = {}
	local bidVolume = {}
	local price = {}
	--for calculating supply & demand
	local askVolume = {}
	--for keeping track of who has traded & the number of trades
	local agentsTraded = {}
	local traderCount = 0
	local bidCount = 0
	
	--define helper functions for algorithm
	
	--[[
		The function empties the ask book and rejects each ask in the book.
	]]
	local rejectAsks = function( c )
		while not table.empty( self.askBook[c] ) do
			local ask = table.remove( self.askBook[c] )
			local seller = self.owner:getPopulation():getAgent( ask.agentID )
			
			if seller.inventory:getInventory( c ) == 0 then
				print("In rejectAsk: "..seller.agentType.." "..ask.agentID.." with no "..c.. " inventory caught")
			end
			seller:rejectAsk( c )
			
			askVolume[c] = askVolume[c] + ask.quantity
		end
	end
	
	--[[
		The function empties the bid book and rejects each bid in the book. The function additionally
		logs the volume & price offered of each bid, in order to perform price calculations.
	]]
	local rejectBids = function( c ) 
		while not table.empty( self.bidBook[c] ) do
			local bid = table.remove( self.bidBook[c] )
			local buyer = self.owner:getPopulation():getAgent( bid.agentID )
			buyer:rejectBid( c )
			
			if not agentsTraded[ buyer.agentID ] then
				bidCount = bidCount + 1
			end
			
			bidAverage[c] = bidAverage[c] + bid.quantity * bid.unitPrice
			bidVolume[c] = bidVolume[c] + bid.quantity
		end
	end
	
	--[[
		The function returns an ask and bid, whose member variable quantity is not zero. The function
		skips the offers whose quantity variable is zero. 
		
		If one of the books are emptied during the process, the function returns -1. Otherwise 
		the function returns the valid ask and bid.
	]]
	local getValidOffers = function( c )
		local ask = table.remove( self.askBook[c] )
		local bid = table.remove( self.bidBook[c] )
		while ask.quantity == 0 or bid.quantity == 0 do
			if ask.quantity == 0 then
				if table.empty( self.askBook[c] ) then return -1 end
				ask = table.remove( self.askBook[c] )
			else
				if table.empty( self.bidBook[c] ) then return -1 end
				bid = table.remove( self.bidBook[c] )
			end
		end
		return ask, bid
	end
	
	for c in pairs( self.commodityPool:getCommodities() ) do
		tradeAverage[c] = 0.0
		tradeVolume[c] = 0
		bidAverage[c] = 0
		bidVolume[c] = 0
		price[c] = 0
		askVolume[c] = 0
		self.sdRatio[c] = 0
		
		if table.empty( self.bidBook[c] ) and table.empty( self.askBook[c] ) then
			--print("continuing loop")
			--continue the loop
		elseif table.empty( self.bidBook[c] ) then
			rejectAsks( c )
		elseif table.empty( self.askBook[c] ) then
			rejectBids( c )
			--new mean price based only on average bidded price
			if bidVolume[c] ~= 0 then
				bidAverage[c] = bidAverage[c] / bidVolume[c]
				price[c] = bidAverage[c]
				self.commodityPool:setCommodityMean( c, price[c])
			end
		else
			table.shuffle( self.bidBook[c] )
			table.shuffle( self.askBook[c] )
			table.sort( self.bidBook[c], Offer.__lt)
			table.sort( self.askBook[c], Offer.gt)
			
			while ( not table.empty( self.bidBook[c] ) ) and ( not table.empty( self.askBook[c] ) ) do
				local ask, bid = getValidOffers( c )
				--check if no valid offers could be found
				if ask == -1 then break end
				
				local qtyToTrade = math.min( bid.quantity, ask.quantity )
				local clearingPrice = ( bid.unitPrice + ask.unitPrice ) / 2
				
				--update metrics
				tradeAverage[c] = tradeAverage[c] + clearingPrice * qtyToTrade
				bidAverage[c] 	= bidAverage[c] + bid.unitPrice * bid.quantity
				bidVolume[c] 	= bidVolume[c] + bid.quantity
				askVolume[c] 	= askVolume[c] + ask.quantity
				tradeVolume[c] 	= tradeVolume[c] + qtyToTrade
				
				local seller = self.owner:getPopulation():getAgent( ask.agentID )
				local buyer = self.owner:getPopulation():getAgent( bid.agentID )
				
				if seller.inventory:getInventory( c ) == 0 then
					print(seller.agentType.." "..ask.agentID.." with no "..c.." inventory caught. Bid was for "..ask.quantity)
				end
					
				buyer:depositToInventory( c, seller:subtractFromInventory( c, qtyToTrade ) )
					
				seller:depositMoney( buyer:subtractMoney( qtyToTrade * clearingPrice) )
					
				seller:acceptAsk( c, clearingPrice )
				buyer:acceptBid( c, clearingPrice )
					
				if not agentsTraded[ seller.agentID ] then
					traderCount = traderCount + 1
					agentsTraded[ seller.agentID ] = true
				end
					
				if not agentsTraded[ buyer.agentID ] then
					traderCount = traderCount + 1
					bidCount = bidCount + 1
					agentsTraded[ buyer.agentID ] = true
				end
			end
			
			--reject any remaining offers
			rejectAsks( c )
			rejectBids( c )
			
			--calculate the price
			if tradeVolume[c] ~= 0 then
				tradeAverage[c] = tradeAverage[c] / tradeVolume[c]
				bidAverage[c] = bidAverage[c] / bidVolume[c]
				
				local fraction = traderCount / self.owner:getPopulation():getPopulationCount()
				price[c] = fraction * tradeAverage[c] + ( 1 - fraction ) * bidAverage[c]
				self.commodityPool:setCommodityMean( c, price[c] )
			end
		end	--if
		--calculate supply/demand ratio
		-- 1: full supply, -1: full demand, 0: balanced
		if ( askVolume[c] + bidVolume[c] ) ~= 0 then
			self.sdRatio[c] = ( askVolume[c] - bidVolume[c] ) / ( askVolume[c] + bidVolume[c] )
		end
	end	--for loop
	
	self.sdLogger:log( self.sdRatio )
	self.priceLogger:log( self.commodityPool:getCommodityPriceTable() )
	self.tradeVolumeLogger:log( tradeVolume )
	self.bidVolumeLogger:log( bidVolume )
	self.askVolumeLogger:log( askVolume )
end

function ClearingHouse:getCommodityMean( c )
	return self.commodityPool:getCommodityMean( c )
end

function ClearingHouse:getSupplyDemandRatio( c )
	return self.sdRatio[c]
end

require "core/utils"

function ClearingHouse:getCommodities()
	return self.commodityPool:getCommodities()
end

function ClearingHouse:setCommodityPool( pool )
	check( "setCommodityPool", "table", pool, "pool" )
	self.commodityPool = pool
end

function ClearingHouse:setOwner( owner )
	self.owner = owner
end

function ClearingHouse:close()
	self.priceLogger:close()
	self.sdLogger:close()
	self.tradeVolumeLogger:close()
	self.bidVolumeLogger:close()
	self.askVolumeLogger:close()
end

DummyClearinghouse = {}

function DummyClearinghouse:new( object )
	object = objecr or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

function DummyClearinghouse:postBid( offer )			end

function DummyClearinghouse:postAsk( offer )			end

function DummyClearinghouse:resolveOffers()				end

function DummyClearinghouse:getCommodityMean()			end

function DummyClearinghouse:getCommodities()			end

function DummyClearinghouse:setCommodityPool( pool )	end

function DummyClearinghouse:setOwner( owner )			end

function DummyClearinghouse:close()						end
