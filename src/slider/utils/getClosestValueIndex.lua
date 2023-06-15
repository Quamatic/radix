local src = script.Parent.Parent.Parent.Parent
local LuauPolyfill = require(src.LuauPolyfill)
local Array = LuauPolyfill.Array

local function getClosestValueIndex(values: { number }, nextValue: number)
	if #values == 1 then
		return 0
	end

	local distances = Array.map(values, function(value)
		return math.abs(value - nextValue)
	end)

	local closestDistance = math.min(unpack(distances))

	return Array.indexOf(distances, closestDistance)
end

return getClosestValueIndex
