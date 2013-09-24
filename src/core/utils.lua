
--[[
	Fisher-Yates shuffling algorithm, algorithm obtained from
	http://www.ludicroussoftware.com/blog/2011/01/07/table-shuffling-in-luacorona/
	on 30.7.2013
]]
function table.shuffle(t)
	assert(t, "table.shuffle() expected a table, got nil")
	local iterations = #t
	local j
	for i = iterations, 2, -1 do
		j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
end

--[[
	This function checks for either
	a) an empty array (no elements )
	b) nil table

	If either case holds, the function returns true. Else, it returns false.
]]
function table.empty(t)
	--check for table being nil
	if t == nil then
		return true
	end

	--then check for empty table
	if next(t) == nil then
		return true
	end
	return false
end


--[[
	This function checks for NANs.
]]
function isNumber(num)
	return num == num
end

--[[
	This function checks for integers
]]
function isInteger(x)
	return math.floor(x) == x
end

--[[
	This function returns a random real number in the range [a, b].
]]
function random(a, b)
	return a + (b - a) * math.random()
end

--[[
	Function argument check.
	
	parameters:
	
	funcname -- the name of the function, as a string
	an array of the arguments, listed in the following order:
	[ the type (as a string), the variable, the name of the variable (as a string) ]
]]
function check(funcname, ...)
    local arg = {...}
 
    if (type(funcname) ~= "string") then
        error("Argument type mismatch at 'check' ('funcname'). Expected 'string', got '"..type(funcname).."'.", 2)
    end
    if (#arg % 3 > 0) then
        error("Argument number mismatch at 'check'. Expected #arg % 3 to be 0, but it is "..(#arg % 3)..".", 2)
    end

    for i=1, #arg-2, 3 do
        if (type(arg[i]) ~= "string" and type(arg[i]) ~= "table") then
            error("Argument type mismatch at 'check' (arg #"..i.."). Expected 'string' or 'table', got '"..type(arg[i]).."'.", 2)
        elseif (type(arg[i+2]) ~= "string") then
            error("Argument type mismatch at 'check' (arg #"..(i+2).."). Expected 'string', got '"..type(arg[i+2]).."'.", 2)
        end
 
        if (type(arg[i]) == "table") then
            local aType = type(arg[i+1])
            for _, pType in next, arg[i] do
                if (aType == pType) then
                    aType = nil
                    break
                end
            end
            if (aType) then
                error("Argument type mismatch at '"..funcname.."' ('"..arg[i+2].."'). Expected '"..table.concat(arg[i], "' or '").."', got '"..aType.."'.", 3)
            end
        elseif (type(arg[i+1]) ~= arg[i]) then
            error("Argument type mismatch at '"..funcname.."' ('"..arg[i+2].."'). Expected '"..arg[i].."', got '"..type(arg[i+1]).."'.", 3)
        end
    end
end
