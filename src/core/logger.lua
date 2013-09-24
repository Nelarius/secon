
require "core/utils"

--[[
	This class can be used to log tables which associate a string with a number, which varies
	each round. The strings title each column, and the numbers are stored in the columns.
	
	Use-case:
	self.logger = Logger:new{ name = "a_file.txt", file = nil, round = 1 }
]]
Logger = {
			name = "",
			file = nil,
			round = 1
		}
		
function Logger:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

function Logger:open( fileName, map )
	self.file = assert( io.open( fileName, "w" ))
	
	--write the first line
	self.file:write(string.format("%-11s", "round"))
	for key in pairs( map ) do
		self.file:write(string.format("%-11s", key))
	end
	self.file:write( "\n" )
end

function Logger:log( map )
	if self.file == nil then
		print("opened file "..self.name)
		self:open( self.name, map )
	end
	
	self.file:write( string.format( "%-11d", self.round ) )
	self.round = self.round + 1
	
	--write map values
	for key in pairs( map ) do
		if isInteger( map[key] ) then
			self.file:write(string.format( "%-11d", map[key] ) )
		else
			self.file:write(string.format( "%-11.2f", map[key] ) )
		end
	end
	self.file:write("\n")
	
end

function Logger:close()
	self.file:close()
end

--[[
	Empty dummy logger if you don't want to output to files
]]

NullLogger = {}

function NullLogger:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

function NullLogger:open( fileName, map )
	--empty
end

function NullLogger:log( map )
	--empty
end

function NullLogger:close()
	--empty
end

--[[
	Turn the logging functionality off from here
]]
LoggerLocator = { type = Logger }

function LoggerLocator.getLogger( fileName )
	return LoggerLocator.type:new{ name = fileName, file = nil, round = 1 }
end
