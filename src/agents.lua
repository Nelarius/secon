
require "core/agent"
require "core/range"

------------------------------------------------------------------------------
--Food production rules
------------------------------------------------------------------------------
function foodProduction( self )
	local hasWood = function()
		if self.inventory.wood >= 1 then
			return true
		end
		return false
	end
	
	local hasTools = function()
		if self.inventory.tools >= 1 then
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
		self:consume( "wood", 1 )
	else
		--penalty for idling
		self:subtractMoney( 2.0 )
	end
	
	self:checkAcquisitions( "wood", "tools" )
	
	if self.inventory.food >= self.commoditySellThreshold.food then
		self:createAsk( "food" )
	end
end


------------------------------------------------------------------------------
--Wood production rules
------------------------------------------------------------------------------
function woodProduction( self )
	local hasFood = function()
		if self.inventory.food >= 1 then
			return true
		end
		return false
	end
	
	local hasTools = function()
		if self.inventory.tools >= 1 then
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
	
	if self.inventory.wood >= self.commoditySellThreshold.wood then
		self:createAsk( "wood" )
	end
end

------------------------------------------------------------------------------
--Ore production rules
------------------------------------------------------------------------------
function oreProduction( self )
	local hasFood = function()
		if self.inventory.food >= 1 then
			return true
		end
		return false
	end
	
	local hasTools = function()
		if self.inventory.tools >= 1 then
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
	
	if self.inventory.ore >= self.commoditySellThreshold.ore then
		self:createAsk( "ore" )
	end
	
end

------------------------------------------------------------------------------
--Metal production rules
------------------------------------------------------------------------------
function metalProduction( self )
	local hasFood = function()
		if self.inventory.food >= 1 then
			return true
		end
		return false
	end
	
	local hasTools = function()
		if self.inventory.tools >= 1 then
			return true
		end
		return false
	end
	
	if hasFood() and hasTools() then
		--convert all ore into metal
		--consume 1 unit of food
		--break tool with 0.3 prob
		self:produce( "metal", self:consumeAll( "ore" ) )
		self:consume( "food", 1 )
		local x = math.random()
		if x < 0.3 then
			self:consume( "tools", 1 )
		end
	elseif hasFood() then
		--convert at most 2 units of ore into metal
		--consume 1 unit of food
		self:consume( "food", 1 )
		local convert = math.min( self.inventory.ore, 2 )
		self:consume( "ore", convert )
		self:produce( "metal", convert )
	else
		--penalty
		self:subtractMoney( 2.0 )
	end
	
	self:checkAcquisitions( "ore", "food", "tools" )
	
	if self.inventory.metal >= self.commoditySellThreshold.metal then
		self:createAsk( "metal" )
	end
end

------------------------------------------------------------------------------
--Tool production rules
------------------------------------------------------------------------------
function toolProduction( self )
	local hasFood = function()
		if self.inventory.food >= 1 then
			return true
		end
		return false
	end
	
	local hasMetal = function()
		if self.inventory.metal >= 1 then
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
	
	if self.inventory.tools >= self.commoditySellThreshold.tools then
		self:createAsk( "tools" )
	end
end

------------------------------------------------------------------------------
--Farmer parameters
------------------------------------------------------------------------------
Farmer = Agent:new{
					agentID = 0,
					agentType = "Farmer",
					priceBelief = {
									wood = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] },
									tools = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									ore = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									metal = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									food = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] }
									},
					observedTrades = {},
					inventory = {
								wood = math.random(0,50),
								tools = math.random(0,50),
								ore = math.random(0,50),
								metal = math.random(0,50),
								food = math.random(0,50)
								},
					commoditySellThreshold = {
												wood = 30,
												tools = 30,
												ore = 30,
												metal = 30,
												food = 30
												},
					commodityAcquireThreshold = {
												wood = 10,
												tools = 10,
												ore = 10,
												metal = 10,
												food = 10
												},
					inventoryLimit = {
										wood = 50,
										tools = 50,
										ore = 50,
										metal = 50,
										food = 50
									},
					money = 20 + 30 * math.random(),
					profit = 0.0,
					moneyBidded = 0.0,
					owner = nil,
					population = nil,
					clearingHouse = nil,
					productionRules = { [1] = foodProduction }
					}
					
					
------------------------------------------------------------------------------
--Woodcutter parameters
------------------------------------------------------------------------------
Woodcutter = Agent:new{
					agentID = 0,
					agentType = "Woodcutter",
					priceBelief = {
									wood = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] },
									tools = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									ore = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									metal = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									food = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] }
									},
					observedTrades = {},
					inventory = {
								wood = math.random(0,50),
								tools = math.random(0,50),
								ore = math.random(0,50),
								metal = math.random(0,50),
								food = math.random(0,50)
								},
					commoditySellThreshold = {
												wood = 30,
												tools = 30,
												ore = 30,
												metal = 30,
												food = 30
												},
					commodityAcquireThreshold = {
												wood = 10,
												tools = 10,
												ore = 10,
												metal = 10,
												food = 10
												},
					inventoryLimit = {
										wood = 50,
										tools = 50,
										ore = 50,
										metal = 50,
										food = 50
									},
					money = 20 + 30 * math.random(),
					profit = 0.0,
					moneyBidded = 0.0,
					owner = nil,
					population = nil,
					clearingHouse = nil,
					productionRules = { [1] = woodProduction }
					}
					
					
------------------------------------------------------------------------------
--Miner parameters
------------------------------------------------------------------------------
Miner = Agent:new{
					agentID = 0,
					agentType = "Miner",
					priceBelief = {
									wood = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] },
									tools = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									ore = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									metal = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									food = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] }
									},
					observedTrades = {},
					inventory = {
								wood = math.random(0,50),
								tools = math.random(0,50),
								ore = math.random(0,50),
								metal = math.random(0,50),
								food = math.random(0,50)
								},
					commoditySellThreshold = {
												wood = 30,
												tools = 30,
												ore = 30,
												metal = 30,
												food = 30
												},
					commodityAcquireThreshold = {
												wood = 10,
												tools = 10,
												ore = 10,
												metal = 10,
												food = 10
												},
					inventoryLimit = {
										wood = 50,
										tools = 50,
										ore = 50,
										metal = 50,
										food = 50
									},
					money = 20 + 30 * math.random(),
					profit = 0.0,
					moneyBidded = 0.0,
					owner = nil,
					population = nil,
					clearingHouse = nil,
					productionRules = { [1] = oreProduction }
					}

					
------------------------------------------------------------------------------
--Refiner parameters
------------------------------------------------------------------------------
Refiner = Agent:new{
					agentID = 0,
					agentType = "Refiner",
					priceBelief = {
									wood = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] },
									tools = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									ore = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									metal = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									food = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] }
									},
					observedTrades = {},
					inventory = {
								wood = math.random(0,50),
								tools = math.random(0,50),
								ore = math.random(0,50),
								metal = math.random(0,50),
								food = math.random(0,50)
								},
					commoditySellThreshold = {
												wood = 30,
												tools = 30,
												ore = 30,
												metal = 30,
												food = 30
												},
					commodityAcquireThreshold = {
												wood = 10,
												tools = 10,
												ore = 10,
												metal = 10,
												food = 10
												},
					inventoryLimit = {
										wood = 50,
										tools = 50,
										ore = 50,
										metal = 50,
										food = 50
									},
					money = 20 + 30 * math.random(),
					profit = 0.0,
					moneyBidded = 0.0,
					owner = nil,
					population = nil,
					clearingHouse = nil,
					productionRules = { [1] = metalProduction }
					}
					
			
------------------------------------------------------------------------------
--Blacksmith parameters
------------------------------------------------------------------------------
Blacksmith = Agent:new{
					agentID = 0,
					agentType = "Blacksmith",
					priceBelief = {
									wood = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] },
									tools = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									ore = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									metal = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ]},
									food = Range:new{ mean = 3, range = 2, state = RangeState[ "Unclamped" ] }
									},
					observedTrades = {},
					inventory = {
								wood = math.random(0,50),
								tools = math.random(0,50),
								ore = math.random(0,50),
								metal = math.random(0,50),
								food = math.random(0,50)
								},
					commoditySellThreshold = {
												wood = 30,
												tools = 30,
												ore = 30,
												metal = 30,
												food = 30
												},
					commodityAcquireThreshold = {
												wood = 10,
												tools = 10,
												ore = 10,
												metal = 10,
												food = 10
												},
					inventoryLimit = {
										wood = 50,
										tools = 50,
										ore = 50,
										metal = 50,
										food = 50
									},
					money = 20 + 30 * math.random(),
					profit = 0.0,
					moneyBidded = 0.0,
					owner = nil,
					population = nil,
					clearingHouse = nil,
					productionRules = { [1] = toolProduction }
					}

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
						