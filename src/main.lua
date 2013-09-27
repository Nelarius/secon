
package.path = "C:\\Users\\Nelarius\\Documents\\LuaProjects\\secon\\src\\?.lua"

--seed before tests are run
math.randomseed( os.time() )

require "test/test"

--print("\nHit enter to finish.")
--local x = io.read()

require "core/economy"

local econ = Economy:new()
econ:run( 400 )

--[[for i = 1,30 do
	econ = Economy:new()
	print("running economy #"..i)
	econ:run( 400 )
end]]
