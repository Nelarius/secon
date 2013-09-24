

function enum( names )
	local __enumId = 0
	local t = {}
	for _, k in ipairs( names ) do
		t[k] = __enumId
		__enumId = __enumId + 1
	end
	return t
end
