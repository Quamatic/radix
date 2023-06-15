local getStepsBetweenValues = require(script.Parent.getStepsBetweenValues)

local function hasMinStepsBetweenValues(values: { number }, minStepsBetweenValues: number)
	if minStepsBetweenValues > 0 then
		local stepsBetweenValues = getStepsBetweenValues(values)
		local actualMinStepsBetweenValues = math.min(unpack(stepsBetweenValues))
		return actualMinStepsBetweenValues >= minStepsBetweenValues
	end

	return false
end

return hasMinStepsBetweenValues
