local src = script.Parent.Parent.Parent.Parent
local LuauPolyfill = require(src.LuauPolyfill)
local Array = LuauPolyfill.Array

type Array<T> = LuauPolyfill.Array<T>

local function wrapArray<T>(array: Array<T>, startIndex: number)
	return Array.map(array, function(_, index)
		return array[(startIndex + index) % #array]
	end)
end

return wrapArray
