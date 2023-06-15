local function convertValueToPercentage(value: number, min: number, max: number)
	local maxSteps = max - min
	local percentPerStep = 100 / maxSteps
	local percentage = percentPerStep * (value - min)
	return math.clamp(percentage, 0, 100)
end

return convertValueToPercentage
