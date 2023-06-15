local linearScale = require(script.Parent.linearScale)

local function getThumbInBoundsOffset(width: number, left: number, direction: number)
	local halfWidth = width / 2
	local halfPercent = 50
	local offset = linearScale({ 0, halfPercent }, { 0, halfWidth })
	return (halfWidth - offset(left) * direction) * direction
end

return getThumbInBoundsOffset
