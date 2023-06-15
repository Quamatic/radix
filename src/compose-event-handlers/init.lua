local function composeEventHandlers(originalEventHandler, ourEventHandler)
	return function(...)
		if originalEventHandler ~= nil then
			originalEventHandler(...)
		end

		return ourEventHandler(...)
	end
end

return composeEventHandlers
