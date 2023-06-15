local function roundValue(value: number, decimalCount: number)
	local rounder = math.pow(10, decimalCount)
	return math.round(value * rounder) / rounder
end

return roundValue
