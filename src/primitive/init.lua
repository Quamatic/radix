local React = require(script.Parent.Parent.React)
local LuauPolyfill = require(script.Parent.Parent.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object

local Slot = require(script.Parent.slot).Slot

local NODES = {
	"Frame",
	"TextLabel",
	"TextButton",
	"TextBox",
	"ImageLabel",
	"ImageButton",
	"CanvasGroup",
}

local Primitive = Array.reduce(NODES, function(primitive, node)
	local Node = React.forwardRef(function(props, ref)
		local asChild, primitiveProps = props.asChild, Object.assign({}, props, {
			asChild = Object.None,
		})

		local Component = if asChild then Slot else node
		return React.createElement(Component, Object.assign({}, primitiveProps, { ref = ref }))
	end)

	Node.displayName = `Primitive.{node}`

	return Object.assign({}, primitive, { [node] = Node })
end, {})

return Primitive
