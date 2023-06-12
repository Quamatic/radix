local src = script.Parent.Parent
local React = require(src.React)

type PossibleRef<T> = React.Ref<T> | nil

local function setRef<T>(ref: PossibleRef<T>, value: T)
	if typeof(ref) == "function" then
		ref(value)
	elseif ref ~= nil then
		ref.current = value
	end
end

local function composeRefs<T>(...: { PossibleRef<T> })
	local refs = { ... }

	return function(node: T)
		for _, ref in refs do
			setRef(ref, node)
		end
	end
end

local function useComposedRefs<T>(...: { PossibleRef<T> })
	return React.useCallback(composeRefs(...), { ... })
end

return {
	useComposedRefs = useComposedRefs,
	composeRefs = composeRefs,
}
