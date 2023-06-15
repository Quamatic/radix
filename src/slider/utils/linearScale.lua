local function linearScale(input: { number }, output: { number })
	return function(value: number)
		if input[1] == input[2] or output[1] == output[2] then
			return output[1]
		end
		local ratio = (output[2] - output[1]) / (input[2] - input[1])
		return output[1] + ratio * (value - input[1])
	end
end

return linearScale
