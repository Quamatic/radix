local function getDecimalCount(value: number)
	return #(tostring(value):split(".")[2] or "")
end

return getDecimalCount
