
local LuaUnit = require "test/luaunit"
require "core/population"
require "core/utils"
require "core/fifoq"
require "core/agent"
require "core/offer"
require "core/range"
require "core/inventory"

--[[
	This file contains tests for the following classes:
	
	FifoQ
	Agent
	Offer
	Range
	Inventory
]]



TestFifoQEmpty = {}

function TestFifoQEmpty:setUp()
	self.queue = FifoQ:new()
end

function TestFifoQEmpty:test1_queuePopsBackNilWhenEmpty()
	assertEquals( self.queue:dequeue(), nil )
end

function TestFifoQEmpty:test2_getMeanReturnsMinusOneWhenEmpty()
	assertEquals( self.queue:getMean(), -1 )
end

function TestFifoQEmpty:test3_getMaxReturnsMinusOneWhenEmpty()
	assertEquals( self.queue:getMax(), -1 )
end

function TestFifoQEmpty:test4_getMinReturnsMinusOneWhenEmpty()
	assertEquals( self.queue:getMin(), -1 )
end

function TestFifoQEmpty:test5_getMeanReturnsCorrectForTwoSameValues()
	self.queue:enqueue(2)
	self.queue:enqueue(2)
	assertEquals( self.queue:getMean(), 2 )
end

function TestFifoQEmpty:test6_getMeanReturnsCorrectForTwoDifferentValues()
	self.queue:enqueue(2)
	self.queue:enqueue(3)
	assertEquals( self.queue:getMean(), 2.5 )
end

TestFifoQOne = {}

function TestFifoQOne:setUp()
	self.queue = FifoQ:new()
	self.queue:enqueue(3)
end

function TestFifoQOne:test1_getMeanReturnsCorrectWhenOneElement()
	assertEquals( self.queue:getMean(), 3 )
end

function TestFifoQOne:test2_getMaxReturnsCorrectWhenOneElement()
	assertEquals( self.queue:getMax(), 3 )
end

function TestFifoQOne:test3_getMinReturnsCorrectWhenOneElement()
	assertEquals( self.queue:getMin(), 3 )
end

function TestFifoQOne:test4_getMinReturnsMinusOneAfterLastElementPopped()
	self.queue:dequeue()
	assertEquals( self.queue:getMin(), -1 )
end

function TestFifoQOne:test5_getMaxReturnsMinusOneAfterLastElementPopped()
	self.queue:dequeue()
	assertEquals( self.queue:getMax(), -1 )
end

function TestFifoQOne:test6_getMinReturnsCorrectAfterOneElementPopped()
	self.queue:enqueue(2)
	self.queue:dequeue()
	assertEquals( self.queue:getMin(), 2 )
end

function TestFifoQOne:test7_getMaxReturnsCorrectAfterOneElementPopped()
	self.queue:enqueue(4)
	self.queue:dequeue()
	assertEquals( self.queue:getMax(), 4 )
end

function TestFifoQOne:test8_getMeanReturnsCorrectAfterOneElementPopped()
	self.queue:enqueue(4)
	self.queue:dequeue()
	assertEquals( self.queue:getMean(), 4 )
end

function TestFifoQOne:test9_getMeanReturnsCorrectForThreeDifferentElements()
	self.queue:enqueue(2)
	self.queue:enqueue(4)
	assertEquals( self.queue:getMean(), 3 )
end

function TestFifoQOne:test10_getMeanReturnsCorrectAfterPopAndPush()
	self.queue:dequeue()
	self.queue:enqueue(2)
	assertEquals( self.queue:getMean(), 2 )
end

function TestFifoQOne:test11_isEmptyReturnsFalseWithOneElementAdded()
	assertEquals( self.queue:isEmpty(), true )
end

function TestFifoQOne:test12_isEmptyReturnsTrueWithTwoElementsAdded()
	self.queue:enqueue(2)
	assertEquals( self.queue:isEmpty(), false )
end

function TestFifoQOne:test13_isEmptyReturnsFalseWithTwoElementsAddedThenOneRemoved()
	self.queue:enqueue(2)
	self.queue:dequeue()
	assertEquals( self.queue:isEmpty(), true )
end

------------------------------------------------------------------------------
--Agent tests
------------------------------------------------------------------------------

TestAgent = {}

function TestAgent:setUp()
	self.agent = Agent:new
	{
		agentID = 0,
		agentType = "",
		priceBelief = {},
		observedTrades = {},
		inventory = Inventory:new{ stock = { wood = 5 }, limit = { wood = 20 } },
		commoditySellThreshold = { wood = 10 },
		commodityAcquireThreshold = { wood = 5 },
		money = 20.0,
		profit = 0.0,
		moneyBidded = 0.0,
		beliefIsUpdated = { wood = false },
		owner = nil,
		clearingHouse = DummyClearinghouse:new(),
		population = DummyPopulation:new(),
		productionRules = {}
	}
	
	local temp = self.agent.inventory:getInventory( "wood" )
	--assert( nil > 0 )
	
	--create dummy clearingHouse
	local asdf = {}
	asdf.getCommodityMean = function( c ) return 5.0 end
	self.agent.clearingHouse = asdf
	
	--create price belief
	self.agent.priceBelief.wood = Range:new{ mean = 4.0, range = 2.0, state = 1 }
end

function TestAgent:test1_SubtractMoneySubtractsCorrectWhenMoreThanEnough()
	self.agent:subtractMoney( 15.0 )
	assertEquals( self.agent.money, 5.0 )
end

function TestAgent:test2_SubtractMoneySubtractsCorrectWhenLessThanEnough()
	self.agent:subtractMoney( 30.0 )
	assertEquals( self.agent.money, 0.0 )
end

function TestAgent:test3_SubtractMoneyReturnsCorrectWhenLessThanEnough()
	local result = self.agent:subtractMoney( 30.0 )
	assertEquals( result, 20.0 )
end

function TestAgent:test4_SubtractMoneyReturnsCorrectWhenMoreThanEnough()
	local result = self.agent:subtractMoney( 15 )
	assertEquals( result, 15 )
end

function TestAgent:test5_DepositMoneyDepositsCorrectly()
	self.agent:depositMoney( 10 )
	assertEquals( self.agent.money, 30 )
end

function TestAgent:test6_DepositToInventoryDepositsCorrectAmount()
	self.agent:depositToInventory( "wood", 5 )
	assertEquals( self.agent.inventory:getInventory( "wood" ), 10 )
end

function TestAgent:test7_SubtractFromInventorySubtractsCorrectAmountWhenMoreThanEnough()
	self.agent:subtractFromInventory( "wood", 3 )
	assertEquals( self.agent.inventory:getInventory( "wood" ), 2 )
end

function TestAgent:test8_SubtractFromInventoryReturnsCorrectAmountWhenMoreThanEnough()
	local result = self.agent:subtractFromInventory( "wood", 3 )
	assertEquals( result, 3 )
end

function TestAgent:test9_SubtractFromInventorySubtractsCorrectAmountWhenLessThanEnough()
	self.agent:subtractFromInventory( "wood", 6 )
	assertEquals( self.agent.inventory:getInventory( "wood" ), 0 )
end

function TestAgent:test10_SubtractFromInventoryReturnsCorrectWhenLessThanEnough()
	local result = self.agent:subtractFromInventory( "wood", 6 )
	assertEquals( result, 5 )
end

function TestAgent:test11_ProduceAddsToInventory()
	self.agent:produce( "wood", 5 )
	assertEquals( self.agent.inventory:getInventory( "wood" ), 10 )
end

function TestAgent:test12_ConsumeSubtractsFromInventory()
	self.agent:consume( "wood", 2 )
	assertEquals( self.agent.inventory:getInventory( "wood" ), 3 )
end

function TestAgent:test13_DetermineSaleQuantityPreventsUnderSelling()
	--observe some dummy trades
	self.agent:observeTrade( "wood", 10.0 )
	self.agent:observeTrade( "wood", 20.0 )
	
	self.agent.inventory:setInventory( "wood", 15 )
	local result = self.agent:determineSaleQuantity( "wood" )
	assertEquals( result, 3 )
end

function TestAgent:test14_DeterminePurchaseQuantityPreventsOverPaying()
	self.agent.inventory:setInventory( "wood", 5 )
	self.agent:observeTrade( "wood", 1.0 )
	self.agent:observeTrade( "wood", 3.0 )
	
	local result = self.agent:determinePurchaseQuantity( "wood" )
	assertEquals( result, 5 )
end

function TestAgent:test15_DetermineSaleQuantityDoesNotRespondToOverPrice()
	self.agent.inventory:setInventory( "wood", 15 )
	self.agent:observeTrade( "wood", 3.0 )
	self.agent:observeTrade( "wood", 1.0 )
	
	local result = self.agent:determineSaleQuantity( "wood" )
	assertEquals( result, 5 )
end

function TestAgent:test16_DeterminePurchaseQuantityDoesNotRespondToUnderPrice()
	self.agent.inventory:setInventory( "wood", 5 )
	self.agent:observeTrade( "wood", 10.0 )
	self.agent:observeTrade( "wood", 20.0 )
	
	local result = self.agent:determinePurchaseQuantity( "wood" )
	assertEquals( result, 15 )
end

function TestAgent:test17_AcceptBidShrinksBeliefRange()
	local old = self.agent.priceBelief.wood:getRange()
	local new = old - 0.1 * self.agent.priceBelief.wood:getMean()
	self.agent:acceptBid( "wood", 4.0 )
	assertEquals( self.agent.priceBelief.wood:getRange(), new )
end

function TestAgent:test18_AcceptBidTranslatesBeliefRangeWhenOverPaying()
	self.agent.priceBelief.wood.mean = 15.0
	local old = self.agent.priceBelief.wood:getMean()
	local new = old + 0.25 * ( 5.0 - self.agent.priceBelief.wood:getMean() )
	self.agent:acceptBid( "wood", 20.0 )
	assertEquals( self.agent.priceBelief.wood:getMean(), new )
end

function TestAgent:test19_AcceptAskShrinksBeliefRange()
	local old = self.agent.priceBelief.wood:getRange()
	local new = old - 0.1 * self.agent.priceBelief.wood:getMean()
	self.agent:acceptAsk( "wood", 4.0 )
	assertEquals( self.agent.priceBelief.wood:getRange(), new)
end

function TestAgent:test20_AcceptAskTranslatesBeliefRangeWhenUnderSelling()
	self.agent.priceBelief.wood.mean = 1.1
	local old = self.agent.priceBelief.wood:getMean()
	local new = old + 0.25 * ( 5.0 - self.agent.priceBelief.wood:getMean() )
	self.agent:acceptAsk( "wood", 1.0 )
	assertEquals( self.agent.priceBelief.wood:getMean(), new )
end

function TestAgent:test21_AcceptBidDoesNotTranslateWhenUnderPaying()
	self.agent.priceBelief.wood.mean = 1.1
	self.agent:acceptBid( "wood", 5.0 )
	assertEquals( self.agent.priceBelief.wood:getMean(), 1.1 )
end

function TestAgent:test22_AcceptAskDoesNotTranslateWhenOverSelling()
	self.agent.priceBelief.wood.mean = 15.0
	self.agent:acceptAsk( "wood", 5.0 )
	assertEquals( self.agent.priceBelief.wood:getMean(), 15.0 )
end

function TestAgent:test23_SubtractFromInventoryAffectsOnlyOneAgent()
	local anotherAgent = Agent:new
	{
		agentID = 0,
		agentType = "",
		priceBelief = {},
		observedTrades = {},
		inventory = { wood = 5 },
		commoditySellThreshold = { wood = 10 },
		commodityAcquireThreshold = { wood = 5 },
		inventoryLimit = { wood = 20 },
		money = 20.0,
		profit = 0.0,
		moneyBidded = 0.0,
		owner = nil,	--is this variable needed?
		clearingHouse = nil,
		population = DummyPopulation:new(),
		productionRules = {}
	}
	self.agent:subtractFromInventory( "wood", 3 )
	assertEquals( anotherAgent.inventory.wood, 5 )
end

------------------------------------------------------------------------------
--Offer tests
------------------------------------------------------------------------------

TestOffer = {}

function TestOffer:setUp()
	local offer1 = Offer:new
	{
		agentID = 0,
		commodity = "commodity 1",
		quantity = 0,
		unitPrice = 1.0
	}
	
	local offer2 = Offer:new
	{
		agentID = 0,
		commodity = "commodity 2",
		quantity = 0,
		unitPrice = 2.0
	}
	
	self.offer_1 = offer1
	self.offer_2 = offer2
	
	local offer3 = Offer:new
	{
		agentID = 0,
		commodity = "commodity 3",
		quantity = 0,
		unitPrice = 3.0
	}
	
	local offer4 = Offer:new
	{
		agentID = 0,
		commodity = "commodity 4",
		quantity = 0,
		unitPrice = 4.0
	}
	
	self.offerTable = {}
	self.offerTable[1] = offer1
	self.offerTable[2] = offer2
	self.offerTable[3] = offer3
	self.offerTable[4] = offer4
	
	table.shuffle(self.offerTable)
end

function TestOffer:test1_OfferIsComparable()
	assertEquals( self.offer_1 < self.offer_2, true )
end

function TestOffer:test2_SortWorksOnOfferIncreasingOrder()
	table.sort( self.offerTable, Offer.__lt )
	assertEquals( self.offerTable[1].commodity, "commodity 1" )
	assertEquals( self.offerTable[2].commodity, "commodity 2" )
	assertEquals( self.offerTable[3].commodity, "commodity 3" )
end

function TestOffer:test3_SortWorksOnOfferDescendingOrder()
	table.sort( self.offerTable, Offer.gt )
	assertEquals( self.offerTable[1].commodity, "commodity 4" )
	assertEquals( self.offerTable[2].commodity, "commodity 3" )
	assertEquals( self.offerTable[3].commodity, "commodity 2" )
end

------------------------------------------------------------------------------
--Range tests
------------------------------------------------------------------------------

TestRange = {}

function TestRange:setUp()
	self.range = Range:new{ mean = 3.0, range = 2.0 }
end

function TestRange:test1_ScaleRangeScalesCorrect()
	self.range:scaleRange( 2.0 )
	assertEquals( self.range.range, 4.0 )
end

function TestRange:test2_ScaleRangeScalesCorrectWhenHittingZero()
	self.range:scaleRange( 4.0 )
	assertEquals( self.range.range, 8.0 )
	assertEquals( self.range:getMin(), 0 )
end

function TestRange:test3_TranslateRangeTranslatesCorrect()
	self.range:translateRange( 1.0 )
	assertEquals( self.range.mean, 4.0 )
end

function TestRange:test4_TranslateRangeTranslatesCorrectWhenHittingZero()
	self.range:translateRange( -3.0 )
	assertEquals( self.range.mean, 0.0 )
end

function TestRange:test5_TranslateRangeMeanDoesNotGoIntoZero()
	self.range:translateRange( -4.0 )
	assertEquals( self.range.mean, 0 )
	assertEquals( self.range:getMin(), 0 )
end

function TestRange:test6_GetRandomValueDoesNotReturnNegative()
	self.range:translateRange( -4 )
	self.range:translateRange( 4 )
	
	for i = 1, 1000 do
		local x = self.range:getRandomValue()
		assertEquals( x > 0, true )
	end
end

function TestRange:test7_TranslateRangeBehavesCorrectlyAfterClamp()
	self.range:translateRange( -4 )
	self.range:translateRange( 4 )
	
	assertEquals( self.range.mean, 4 )
	assertEquals( self.range:getMin(), 3)
end

function TestRange:test8_ScaleRangeBehavesCorrectlyAfterClamp()
	self.range:scaleRange( 4 )
	self.range:scaleRange( 0.25 )
	
	assertEquals( self.range.mean, 3 )
	assertEquals( self.range:getMin(), 2 )
end

function TestRange:test9_GetRandomDoesNotReturnZeroWhenScaleOffTheCharts()
	self.range:scaleRange( 1000 )
	for i = 1, 1000 do
		local x = self.range:getRandomValue()
		assertEquals( x > 0, true)
	end
end

------------------------------------------------------------------------------
--Inventory tests
------------------------------------------------------------------------------

TestInventory = {}

function TestInventory:setUp()
	self.inv = Inventory:new{ stock = { wood = 10 }, limit = { wood = 20 } }
end

function TestInventory:test1_subtractFromInventorySubtractsCorrectly()
	self.inv:subtractFromInventory( "wood", 5 )
	assertEquals( self.inv:getInventory( "wood" ), 5 )
end

function TestInventory:test2_depositToInventoryDepositsCorrectly()
	self.inv:depositToInventory( "wood", 5 )
	assertEquals( self.inv:getInventory( "wood" ), 15 )
end

function TestInventory:test3_depositToInventoryDoesNotDepositOverLimit()
	--inventory at 10, cannot go over 20
	self.inv:depositToInventory( "wood", 15 )
	assertEquals( self.inv:getInventory( "wood" ), 20 )
end

function TestInventory:test4_subtractFromInventoryDoesNotGoUnderZero()
	--inventory 10, cannot subtract 15
	self.inv:subtractFromInventory( "wood", 15 )
	assertEquals( self.inv:getInventory( "wood" ), 0 )
end

function TestInventory:test5_setInventoryDoesNotSetOverLimit()
	--limit is at 20, cannot set 32
	self.inv:setInventory( "wood", 32 )
	assertEquals( self.inv:getInventory( "wood" ), 20 )
end

function TestInventory:test6_setLimitLowerThanInventoryLowersInventory()
	self.inv:setLimit( "wood", 5)	--inventory is at 10, so should be 5
	assertEquals( self.inv:getInventory( "wood" ), 5 )
end

function TestInventory:test7_subtractFromInventoryReturnsCorrectWhenSubtractingBeyondZero()
	--inventory is at 10, so should be 10
	local valua = self.inv:subtractFromInventory( "wood", 15 )
	assertEquals( valua, 10 )
end

function TestInventory:test8_subtractFromInventoryReturnsCorrectWhenSubtractingLessThanSupply()
	--inventory is at 10, so should be fine
	local value = self.inv:subtractFromInventory( "wood", 8 )
	assertEquals( value, 8 )
end

function TestInventory:test9_depositDoesNotDepositNegativeAmount()
	--inventory at 10, so should remain at 10
	self.inv:depositToInventory( "wood", -2 )
	assertEquals( self.inv:getInventory( "wood" ), 10 )
end

function TestInventory:test10_subtractDoesNotSubtractNegativeAmount()
	--inventory at 10, so should remain at 10
	self.inv:subtractFromInventory( "wood", -2 )
	assertEquals( self.inv:getInventory( "wood" ), 10 )
end

LuaUnit:run()
