
--[[
	The structure of the commodity pool is the following: 
	
	CommodityPool = {
		pool = {
			"key" = value
		},
		
		price = {
			"key" = value
		}
	}
	
	We create all the key & pool values here, and their respective key & price values.
	The keys in both tables must be the same!
]]

local commodityPool = {}

commodityPool.wood = 1000
commodityPool.food = 1000
commodityPool.ore = 1000
commodityPool.metal = 1000
commodityPool.tools = 1000

--define initial prices for the commodities
local commodityPrice = {}

commodityPrice.wood = 3.0
commodityPrice.food = 3.0
commodityPrice.ore = 3.0
commodityPrice.metal = 3.0
commodityPrice.tools = 3.0

require "core/commoditypool"

local pool = CommodityPool:new()
pool:setCommodityPool( commodityPool )
pool:setCommodityPrice( commodityPrice )

return pool
