local src = script.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object

local Primitive = require(src.Radix.primitive)
local useControllableState = require(src.Radix["use-controllable-state"])

type ToggleProps = {
	pressed: boolean?,
	defaultPressed: boolean?,
	disabled: boolean?,
	onPressedChange: ((pressed: boolean) -> ())?,
}

local Toggle = React.forwardRef(function(props: ToggleProps, forwardedRef)
	local pressedProp = props.pressed
	local defaultPressed = props.defaultPressed or false
	local onPressedChange = props.onPressedChange
	local disabled = props.disabled or false
	local buttonProps = Object.assign({}, props, {
		pressed = Object.None,
		defaultPressed = Object.None,
		disabled = Object.None,
		onPressedChange = Object.None,
	})

	local pressed, setPressed = useControllableState({
		prop = pressedProp,
		defaultProp = defaultPressed,
		onChange = onPressedChange,
	})

	return React.createElement(
		Primitive.ImageButton,
		Object.assign({}, buttonProps, {
			ref = forwardedRef,
			[React.Event.Activated] = function()
				if not disabled then
					setPressed(not pressed)
				end
			end,
		})
	)
end)

Toggle.displayName = "Toggle"

return {
	Root = Toggle,
}
