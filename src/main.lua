
package.path = "C:\\Users\\Nelarius\\Documents\\LuaProjects\\secon\\src\\?.lua"

--seed before tests are run
math.randomseed( os.time() )

require "core/economy"

local econ = Economy:new()
econ:run( 400 )

--[[for i = 1,20 do
	local econ = Economy:new()
	print("running economy #"..i)
	econ:run( 200 )
end]]
