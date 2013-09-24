
--[[
	Utility function which checks for an empty table.
]]
function table.empty(t)
	if next(t) == nil then
		return true
	end
	return false
end


--[[
	This function returns the character count, word count, and line count (in
	that order) of the given file
]]
function getLines(fileName)
	local BUFFER_SIZE = 2^13

	local stdin = io.input()

	local file = io.input(fileName)
	local cc, lc, wc = 0, 0, 0 --define char, line & word count

	while true do
		local lines, rest = file:read(BUFFER_SIZE, "*line")

		if not lines then
			break
		end

		if rest then
			lines = lines .. rest .. '\n'
		end

		cc = cc + string.len(lines)

		--count words in the chunk
		local _, t = string.gsub(lines, "%S+", "")
		wc = wc + t

		--count newline chars in the chunk
		_,t = string.gsub(lines, "\n", "\n")
		lc = lc + t
	end
	--return std input
	io.input(stdin)

	return cc, wc, lc
end

function listFiles(directory)
	local t = {}
	for fileName in io.popen("dir " .. directory .. "/b /a-d"):lines() do
		table.insert(t, fileName)
	end
	return t
end

function listDirs(directory)
	local t = {}
	for dir in io.popen("dir " .. directory .. "/b /ad"):lines() do
		table.insert(t, dir)
	end
	return t
end

--[[
	Returns the path to the filder in which this script was run.
]]
function currentDir()
	local path = string.gsub(arg[0], "\\(%a+)%.(%a+)", "")
	return path
end

--define global variables for total counts
cc, wc, lc = 0, 0, 0

function count(directory)
	local files = listFiles(directory)
	for _, f in ipairs(files) do
		if f == "linecount.lua" then
			--do nothing
		elseif string.find(f, ".lua") then
			local file = directory.."\\"..f
			local charc, wordc, linec = getLines(file)
			print(string.format("%-20s %-6d %-6d %-6d", f, charc, wordc, linec))

			cc = cc + charc
			wc = wc + wordc
			lc = lc + linec
		end
	end

	local dirs = listDirs(directory)
	for _, dir in ipairs(dirs) do
		if dir == ".git" then
			--do nothing
		else
			local temp = directory.."\\"..dir
			count(temp)
		end
	end
end


print(string.format("%-20s %-6s %-6s %-6s", "File name", "chars", "words", "lines"))
print("-------------------------------------")
count(currentDir())
print("-------------------------------------")
print(string.format("%-20s %-6d %-6d %-6d", "Total count", cc, wc, lc))

print("\nPress enter to finish.")
local result = io.read()
