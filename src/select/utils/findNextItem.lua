local src = script.Parent.Parent.Parent.Parent
local LuauPolyfill = require(src.LuauPolyfill)
local Array = LuauPolyfill.Array
local Boolean = LuauPolyfill.Boolean
local String = LuauPolyfill.String

local wrapArray = require(script.Parent.wrapArray)

local function findNextItem<T>(items: { T } & { textValue: string }, search: string, currentItem: T?): T?
	local isRepeated = utf8.len(search) > 1
		and Array.every(Array.from(search), function(char)
			return char == string.sub(search, 1, 1)
		end)

	local normalizedSearch = if isRepeated then string.sub(search, 1, 1) else search
	local currentItemIndex = if Boolean.toJSBoolean(currentItem) then Array.indexOf(items, currentItem) else -1
	local wrappedItems = wrapArray(items, math.max(currentItemIndex, 1))
	local excludeCurrentItem = utf8.len(normalizedSearch) == 1

	if excludeCurrentItem then
		wrappedItems = Array.filter(wrappedItems, function(v)
			return v ~= currentItem
		end)
	end

	local nextItem = Array.find(wrappedItems, function(item)
		return String.startsWith(item.textValue:lower(), normalizedSearch:lower())
	end)

	return if nextItem ~= currentItem then nextItem else nil
end

return findNextItem
