local src = script.Parent.Parent
local React = require(src.React)
local ReactRoblox = require(src.ReactRoblox)
local Object = require(src.LuauPolyfill).Object

local Primitive = require(src.Radix.primitive)

type PortalProps = {
	container: GuiObject?,
}

local Portal = React.forwardRef(function(props: PortalProps, forwardedRef)
	local container = props.container
	local portalProps = Object.assign({}, props, { container = Object.None })

	return if container ~= nil
		then ReactRoblox.createPortal(
			React.createElement(Primitive.Frame, Object.assign({}, portalProps, { ref = forwardedRef })),
			container
		)
		else nil
end)

Portal.displayName = "Portal"

return Portal
