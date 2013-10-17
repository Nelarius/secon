
require "core/agent"

------------------------------------------------------------------------------
--DER speculator definition
------------------------------------------------------------------------------

DERspeculator = MinimalAgent:new{
	agentID = 0,
	agentType = "DERspeculator",
	inventory = {},
	money = 0.0,
	profit = 0.0,
	population = nil,
	clearingHouse = nil
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