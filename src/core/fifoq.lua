
Node = {
		next = nil,
		previous = nil,
		value = nil
}

function Node:new(object)
	object = object or {}
	setmetatable(object, self)
	self.__index = self
	return object
end

--[[
	This data structure is a first-in, first out queue of a constant length. This means that the dequeue
	method does not have to explicitly called; the data structure will dequeue the last value once max 
	queue size is reached. The max queue size is set by the limit parameter.
	
	This class additionally maintains the minimum, maximum and average values of the entries in the queue.
]]
FifoQ = {
		head = nil,
		tail = nil,
		limit = 8,
		count = 0,
		max = -1,
		min = -1
}

function FifoQ:new( object )
	object = object or {}
	setmetatable( object, self )
	self.__index = self
	return object
end

--[[
	This method enqueues the value provided as an argument. If the queue's length exceeds the limit, it
	automatically dequeues the last value in the queue.
	
	Thus the time complexity of this function will occasionally be O(k), where k = limit.
]]
function FifoQ:enqueue( val )
	if val == nil then
		return
	end
	
	local node = Node:new{ next = nil, previous = self.head, value = val }
	--handle first node case:
	if self.head then
		self.head.next = node
	else
		self.tail = node
	end
	self.head = node
	self.count = self.count + 1
	
	--enforce length limit
	if self.count > self.limit then
		self:dequeue()
	end
	
	if val > self.max then
		self.max = val
		if self.min == -1 then
			self.min = self.max
		end
	elseif val < self.min then
		self.min = val
	end
end

--[[
	Time complexity is O(k), where k = limit
]]
function FifoQ:dequeue()
	local toRemove = nil
	--handle last element case:
	if self.count == 1 then
		self.count = 0
		toRemove = self.tail
		self.tail = nil
		self.head = nil
	end
	
	if self.tail then
		local newTail = self.tail.next
		toRemove = self.tail
		newTail.previous = nil
		self.tail = newTail
		self.count = self.count - 1
	end
	
	--min and max have to be recalculated:
	self.max = -1
	self.min = -1
	local node = self.head
	while node do
		if node.value > self.max then
			self.max = node.value
			if self.min == -1 then
				self.min = self.max
			end
		elseif node.value < self.min then
			self.min = node.value
		end
		
		node = node.previous
	end
	
	return toRemove
end

--[[
	This method returns the mean of the values in the queue. Returns -1 if there are no elements in 
	the queue. The time complexity of the method is O(k), where k = limit.
]]
function FifoQ:getMean()
	local node = self.head
	local sum = 0.0
	while node do
		sum = sum + node.value
		node = node.previous
	end
	
	if self.count == 0 then 
		return -1
	end
	
	sum = sum / self.count
	return sum
end

--[[
	Constant time operation.
]]
function FifoQ:getMin()
	return self.min
end

--[[
	Constant time operation.
]]
function FifoQ:getMax()
	return self.max
end

--[[
	Time complexity: O( count )
	
	Returns an array containing all the values in the queue. 
	The latest value is the first one in the array.
]]
function FifoQ:getValues()
	local vals = {}
	local node = self.head
	while node do
		table.insert( vals, node.value )
		node = node.previous
	end
	
	return vals
end

--[[
	Returns true if the count is 1 or 2 (therefore getMax, getMin and getMean are meaningless). Otherwise,
	returns true.
]]
function FifoQ:isEmpty()
	if self.count >= 2 then
		return false
	end
	return true
end

--[[
	Returns the current number of elements in queue.
]]
function FifoQ:getLength()
	return self.count
end
