
require "core/logger"


Population = {
				agentTypes = {},	--associative table between agent type and their count
				agents = {},		--an array
				mostProfitableType = nil,
				owner = nil,
				idCounter = 1,
				bankruptcies = {},
				profitLogger = LoggerLocator.getLogger( "core/profits.dat" ),
				agentLogger = LoggerLocator.getLogger( "core/agents.dat" )
			}

function Population:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

function Population:update()
	local agentTypeProfit = {}
	for t in pairs( self.agentTypes ) do
		agentTypeProfit[t] = 0.0
	end
	
	--update each agent, and at the same time accumulate the total profitability of each agent class
	for _, a in ipairs( self.agents ) do
		if a ~= nil then
			local key = a:getAgentType()
			--first accumulate the profit from last turn
			agentTypeProfit[key] = agentTypeProfit[key] + a:getProfit()
			--and only then perform production, profit reset
			a:performProduction()
		end
	end
	
	--iterate over agentTypeProfit: normalize profit value & get largest key
	for t in pairs( agentTypeProfit ) do
		if self.agentTypes[t] ~= 0 then
			agentTypeProfit[t] = agentTypeProfit[t] / self.agentTypes[t]
		else
			agentTypeProfit[t] = 0
		end
		
		if agentTypeProfit[t] > agentTypeProfit[ self.mostProfitableType ] then
			self.mostProfitableType = t
		end
	end
	--log stuff
	self.profitLogger:log( agentTypeProfit )
	self.agentLogger:log( self.agentTypes )
end

function Population:getMostProfitableAgentType()
	return self.mostProfitableType
end

function Population:createAgent( prototype, index )
	check( "createAgent", "table", prototype, "prototype" )
	--if the most profitable type has not been calculated yet, then just set a dummy type
	if self.mostProfitableType == nil then
		self.mostProfitableType = prototype.agentType
	end
	
	local agent = prototype:new()
	agent.owner = self.owner
	agent.clearingHouse = self.owner:getClearingHouse()
	agent.population = self
	local stringID = agent.agentType
	
	--check for unencountered agent type
	if self.agentTypes[stringID] == nil then
		self.agentTypes[stringID] = 1
	else
		self.agentTypes[stringID] = self.agentTypes[stringID] + 1
	end
	
	if index == nil then	--then insert at the end of the table
		agent.agentID = self.idCounter
		self.idCounter = self.idCounter + 1
		table.insert( self.agents, agent )
	else
		agent.agentID = index
		self.agents[index] = agent
	end
end

function Population:removeAgent( index )
	local stringID = self.agents[index].agentType
	self.agentTypes[stringID] = self.agentTypes[stringID] - 1
	self.agents[index] = nil
end

function Population:flagBankruptcy( id )
	table.insert( self.bankruptcies, id )
end

function Population:removeBankruptcies()
	while not table.empty( self.bankruptcies ) do
		local id = table.remove( self.bankruptcies )
		self:removeAgent( id )
		local t = self.mostProfitableType
		check("removeBankruptcies", "string", self.mostProfitableType, "mostProfitableType")
		--create an agent of the most profitable type
		--obtain the prototype using the global agentAssociationTable
		self:createAgent( agentAssociationTable[t], id )
	end
end

function Population:getAgent( index )
	return self.agents[index]
end

function Population:getPopulationCount()
	return #self.agents
end

function Population:setOwner( owner )
	self.owner = owner
end

function Population:close()
	self.profitLogger:close()
	self.agentLogger:close()
end

------------------------------------------------------------------------------
--A dummy population class
------------------------------------------------------------------------------

DummyPopulation = {}

function DummyPopulation:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

function DummyPopulation:update() end

function DummyPopulation:getMostProfitableAgentType() end

function DummyPopulation:createAgent( prototype, index ) end

function DummyPopulation:removeAgent( index ) end

function DummyPopulation:flagBankruptcy( id ) end

function DummyPopulation:removeBankruptcies() end

function DummyPopulation:getAgent( index ) end

function DummyPopulation:getPopulationCount() end

function DummyPopulation:setOwner( owner ) end

function DummyPopulation:close()	end
