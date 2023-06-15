local src = script.Parent.Parent.Parent.Parent
local LuauPolyfill = require(src.LuauPolyfill)
local Array = LuauPolyfill.Array

local function getStepsBetweenValues(values: { number })
	return Array.map(Array.slice(values, 0, -1), function(value, index)
		return values[index + 1] - value
	end)
end

return getStepsBetweenValues
