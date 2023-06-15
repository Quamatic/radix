local src = script.Parent.Parent.Parent.Parent
local LuauPolyfill = require(src.LuauPolyfill)
local Array = LuauPolyfill.Array

local function getNextSortedValues(prevValues_: { number }?, nextValue: number, atIndex: number)
	local prevValues = if prevValues_ ~= nil then prevValues_ else {}

	local nextValues = table.clone(prevValues)
	nextValues[atIndex] = nextValue

	return Array.sort(nextValues, function(a, b)
		return a - b
	end)
end

return getNextSortedValues
