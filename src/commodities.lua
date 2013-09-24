
local commodityPool = {}

commodityPool.wood = 1000
commodityPool.food = 1000
commodityPool.ore = 1000
commodityPool.metal = 1000
commodityPool.tools = 1000

--define initial prices for the commodities
local commodityPrice = {}

commodityPrice.wood = 4.0
commodityPrice.food = 4.0
commodityPrice.ore = 4.0
commodityPrice.metal = 5.0
commodityPrice.tools = 3.0

require "core/commoditypool"

local pool = CommodityPool:new()
pool:setCommodityPool( commodityPool )
pool:setCommodityPrice( commodityPrice )

return pool
