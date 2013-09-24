
package.path = "C:\\Users\\Nelarius\\Documents\\LuaProjects\\Economy\\src\\?.lua"

--seed before tests are run
math.randomseed( os.time() )

--require "test/test"

--print("\nHit enter to finish.")
--local x = io.read()

require "core/economy"

econ = Economy:new()

econ:run( 100 )
