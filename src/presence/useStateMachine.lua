local src = script.Parent.Parent.Parent
local React = require(src.React)

local function useStateMachine<M>(initialState: M, machine: M & {})
	return React.useReducer(function(state, event)
		local nextState = (machine :: any)[state][event]
		return nextState or state
	end, initialState)
end

return useStateMachine
