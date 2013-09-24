
require "core/population"
require "core/clearinghouse"

Zone = { population = Population:new(), clearingHouse = ClearingHouse:new() }

function Zone:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	
	object.clearingHouse:setOwner( object )
	object.population:setOwner( object )
	
	return object
end

function Zone:initialize()
	--abstract method
end

function Zone:close()
	--abstract method
end

function Zone:update()
	self.population:update()
	
	self.clearingHouse:resolveOffers()
	
	self.population:removeBankruptcies()
end

function Zone:getClearingHouse()
	return self.clearingHouse
end

function Zone:getPopulation()
	return self.population
end

------------------------------------------------------------------------------
--TestZone implementation
------------------------------------------------------------------------------
local pool = require "commodities"
require "agents"

TestZone = Zone:new()

function TestZone:initialize()
	self.clearingHouse:setCommodityPool( pool )
	
	for i = 1, 200, 1 do
		self.population:createAgent( Farmer )
	end

	for i = 1, 200, 1 do
		self.population:createAgent( Woodcutter)
	end
	
	for i = 1, 150, 1 do
		self.population:createAgent( Miner )
	end
	
	for i = 1, 130, 1 do
		self.population:createAgent( Refiner )
	end
	
	for i = 1, 100, 1 do
		self.population:createAgent( Blacksmith )
	end
end

function TestZone:close()
	self.population:close()
	self.clearingHouse:close()
end
