local src = script.Parent.Parent.Parent
local React = require(src.React)

local useCallbackRef = require(script.Parent.Parent["use-callback-ref"])

local function useResizeObserver(element: GuiObject, onResize: () -> ())
	local handleResize = useCallbackRef(onResize)

	React.useLayoutEffect(function()
		local connection = element:GetPropertyChangedSignal("AbsoluteSize"):Connect(handleResize)
		return function()
			connection:Disconnect()
		end
	end, { element, handleResize })
end

return useResizeObserver
