
require "core/agent"
require "core/range"
require "core/inventory"

------------------------------------------------------------------------------
--Food production rules
------------------------------------------------------------------------------
function foodProduction( self )
	local hasWood = function()
		if self.inventory:getInventory( "wood" ) >= 1 then
			return true
		end
		return false
	end
	
	local hasTools = function()
		if self.inventory:getInventory( "tools" ) >= 1 then
			return true
		end
	end
	
	if hasWood() and hasTools() then
		--produce 4 units food
		--consume 1 unit wood
		--consume tool with prob 0.5
		self:produce( "food", 4 )
		self:consume( "wood", 1 )
		local x = math.random()
		if x < 0.5 then
			self:consume( "tools", 1 )
		end
	elseif hasWood() then
		--produce 2 units food
		--consume 1 unit wood
		self:produce( "food", 2 )
		self:consume( "wood", 1, "foodProduction" )
	else
		--penalty for idling
		self:subtractMoney( 2.0 )
	end
	
	self:checkAcquisitions( "wood", "tools" )
	
	if self.inventory:getInventory( "food" ) >= self.commoditySellThreshold.food then
		self:createAsk( "food" )
	end
end


------------------------------------------------------------------------------
--Wood production rules
------------------------------------------------------------------------------
function woodProduction( self )
	local hasFood = function()
		if self.inventory:getInventory( "food" ) >= 1 then
			return true
		end
		return false
	end
	
	local hasTools = function()
		if self.inventory:getInventory( "tools" ) >= 1 then
			return true
		end
		return false
	end
	
	if hasFood() and hasTools() then
		--produce 2 units of wood
		--consume 1 unit of food
		--break tool with prob 0.3
		self:produce( "wood", 2 )
		self:consume( "food", 1 )
		local x = math.random()
		if x < 0.3 then
			self:consume( "tools", 1 )
		end
	--[[elseif hasFood() then
		--produce 1 unit of wood
		--consume 1 unit of food
		self:produce( "wood", 1 )
		self:consume( "food", 1 )]]
	else
		--penalty
		self:subtractMoney( 2.0 )
	end
	
	self:checkAcquisitions( "food", "tools" )
	
	if self.inventory:getInventory( "wood" ) >= self.commoditySellThreshold.wood then
		self:createAsk( "wood" )
	end
end

------------------------------------------------------------------------------
--Ore production rules
------------------------------------------------------------------------------
function oreProduction( self )
	local hasFood = function()
		if self.inventory:getInventory( "food" ) >= 1 then
			return true
		end
		return false
	end
	
	local hasTools = function()
		if self.inventory:getInventory( "tools" ) >= 1 then
			return true
		end
		return false
	end
	
	if hasFood() and hasTools() then
		--produce 4 units of ore
		--consume 1 unit of food
		--break tool with prob 0.5
		self:produce( "ore", 4 )
		self:consume( "food", 1 )
		local x = math.random()
		if x < 0.5 then
			self:consume( "tools", 1)
		end
	elseif hasFood() then
		--produce 2 units of ore
		--consume 1 unit of food
		self:produce( "ore", 4 )
		self:consume( "food", 1 )
	else
		--penalty
		self:subtractMoney( 2.0 )
	end
	
	self:checkAcquisitions( "food", "tools" )
	
	if self.inventory:getInventory( "ore" ) >= self.commoditySellThreshold.ore then
		self:createAsk( "ore" )
	end
	
end

------------------------------------------------------------------------------
--Metal production rules
------------------------------------------------------------------------------
function metalProduction( self )
	local hasFood = function()
		if self.inventory:getInventory( "food" ) >= 1 then
			return true
		end
		return false
	end
	
	local hasTools = function()
		if self.inventory:getInventory( "tools" ) >= 1 then
			return true
		end
		return false
	end
	
	local hasOre = function()
		if self.inventory:getInventory( "ore" ) >= 1 then
			return true
		end
		return false
	end
	
	if hasFood() and hasTools() and hasOre() then
		--convert all ore into metal
		--consume 1 unit of food
		--break tool with 0.3 prob
		self:produce( "metal", self:consumeAll( "ore" ) )
		self:consume( "food", 1 )
		local x = math.random()
		if x < 0.3 then
			self:consume( "tools", 1 )
		end
	elseif hasFood() and hasOre() then
		--convert at most 2 units of ore into metal
		--consume 1 unit of food
		self:consume( "food", 1 )
		local convert = math.min( self.inventory:getInventory( "ore" ), 2 )
		self:consume( "ore", convert )
		self:produce( "metal", convert )
	else
		--penalty
		self:subtractMoney( 2.0 )
	end
	
	self:checkAcquisitions( "ore", "food", "tools" )
	
	if self.inventory:getInventory( "metal" ) >= self.commoditySellThreshold.metal then
		self:createAsk( "metal" )
	end
end

------------------------------------------------------------------------------
--Tool production rules
------------------------------------------------------------------------------
function toolProduction( self )
	local hasFood = function()
		if self.inventory:getInventory( "food" ) >= 1 then
			return true
		end
		return false
	end
	
	local hasMetal = function()
		if self.inventory:getInventory( "metal" ) >= 1 then
			return true
		end
		return false
	end
	
	if hasFood() and hasMetal() then
		--convert all metal into tools
		--consume 1 unit of food
		self:produce( "tools", self:consumeAll( "metal" ) )
		self:consume( "food", 1 )
	else
		--penalty
		self:subtractMoney( 2.0 )
	end
	
	self:checkAcquisitions( "metal", "food" )
	
	if self.inventory:getInventory( "tools" ) >= self.commoditySellThreshold.tools then
		self:createAsk( "tools" )
	end
end

------------------------------------------------------------------------------
--New constructor which randomizes each object's inventory
------------------------------------------------------------------------------
randomizerConstructor = function( self, object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	object.inventory:setInventory( "food", math.random(0, 50) )
	object.inventory:setInventory( "wood", math.random(0, 50) )
	object.inventory:setInventory( "ore", math.random(0, 50) )
	object.inventory:setInventory( "metal", math.random(0, 50) )
	object.inventory:setInventory( "tools", math.random(0, 50) )
	return object
end


------------------------------------------------------------------------------
--Define base agent, which defines most of the boilerplate variables
------------------------------------------------------------------------------
BaseAgent = Agent:new{
	agentID = 0,
	agentType = " ",	--this must be set separately
	priceBelief = 
	{
		wood = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] },
		tools = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
		ore = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
		metal = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
		food = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] }
	},
	observedTrades = {},
	inventory = Inventory:new{
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
	},
	commoditySellThreshold = 
	{
		wood = 30,
		tools = 30,
		ore = 30,
		metal = 30,
		food = 30
	},
	commodityAcquireThreshold = 
	{
		wood = 10,
		tools = 10,
		ore = 10,
		metal = 10,
		food = 10
	},
	money = 20 + 30 * math.random(),
	profit = 0.0,
	moneyBidded = 0.0,
	beliefIsUpdated = 
	{
		wood = false,
		tools = false,
		ore = false,
		metal = false,
		food = false
	},
	owner = nil,
	population = nil,
	clearingHouse = nil,
	productionRules = {  }	--this must be set separately
}

BaseAgent.new = randomizerConstructor

------------------------------------------------------------------------------
--Farmer parameters
------------------------------------------------------------------------------
Farmer = BaseAgent:new()
Farmer.agentType = "Farmer"
Farmer.productionRules = { [1] = foodProduction }
					
					
------------------------------------------------------------------------------
--Woodcutter parameters
------------------------------------------------------------------------------
Woodcutter = BaseAgent:new()
Woodcutter.agentType = "Woodcutter"
Woodcutter.productionRules = { [1] = woodProduction }
					
					
------------------------------------------------------------------------------
--Miner parameters
------------------------------------------------------------------------------
Miner = BaseAgent:new()
Miner.agentType = "Miner"
Miner.productionRules = { [1] = oreProduction }

					
------------------------------------------------------------------------------
--Refiner parameters
------------------------------------------------------------------------------
Refiner = BaseAgent:new()
Refiner.agentType = "Refiner"
Refiner.productionRules = { [1] = metalProduction }
					
			
------------------------------------------------------------------------------
--Blacksmith parameters
------------------------------------------------------------------------------
Blacksmith = BaseAgent:new()
Blacksmith.agentType = "Blacksmith"
Blacksmith.productionRules = { [1] = toolProduction }

------------------------------------------------------------------------------
--Agent association table, used by population
------------------------------------------------------------------------------
agentAssociationTable = {
							["Farmer"] = Farmer,
							["Woodcutter"] = Woodcutter,
							["Miner"] = Miner,
							["Refiner"] = Refiner,
							["Blacksmith"] = Blacksmith,
						}
						