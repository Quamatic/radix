local src = script.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error

type Array<T> = LuauPolyfill.Array<T>

local reactContext = require(src.Radix.context)
local createContextScope = reactContext.createContextScope
type Scope<C = any> = reactContext.Scope<C>

local Primitive = require(src.Radix.primitive)

local Toggle = require(src.Radix.toggle)
local useControllableState = require(src.Radix["use-controllable-state"])

local TOGGLE_GROUP_NAME = "ToggleGroup"

type ScopedProps<P> = P & { __scopeToggleGroup: Scope? }
local createToggleGroupContext, createToggleGroupScope = createContextScope(TOGGLE_GROUP_NAME)

type ToggleGroupSingleProps = {
	type: "single",
}

type ToggleGroupMultipleProps = {
	type: "multiple",
}

local ToggleGroupImplSingle
local ToggleGroupImplMultiple

local ToggleGroup = React.forwardRef(function(props: ToggleGroupSingleProps | ToggleGroupMultipleProps, forwardedRef)
	local type = props.type
	local toggleGroupProps = Object.assign({}, props, { type = Object.None })

	if type == "single" then
		return React.createElement(ToggleGroupImplSingle, Object.assign({}, toggleGroupProps, { ref = forwardedRef }))
	elseif type == "multiple" then
		return React.createElement(ToggleGroupImplMultiple, Object.assign({}, toggleGroupProps, { ref = forwardedRef }))
	end

	error(Error.new(`Missing prop \`type\` expected on \`{TOGGLE_GROUP_NAME}\``))
end)

ToggleGroup.displayName = TOGGLE_GROUP_NAME

type ToggleGroupValueContextValue = {
	type: "single" | "multiple",
	value: Array<string>,
	onItemActivate: (value: string) -> (),
	onItemDeactivate: (value: string) -> (),
}

local ToggleGroupValueProvider, useToggleGroupValueContext = createToggleGroupContext(TOGGLE_GROUP_NAME)
local ToggleGroupImpl

type ToggleGroupImplMultipleProps = {
	value: Array<string>?,
	defaultValue: Array<string>?,
	onValueChange: ((value: Array<string>) -> ())?,
}

ToggleGroupImplMultiple = React.forwardRef(function(props: ScopedProps<ToggleGroupImplMultipleProps>, forwardedRef)
	local valueProp = props.value
	local defaultValue = props.defaultValue
	local onValueChange = props.onValueChange or function() end
	local toggleGroupMultipleProps = Object.assign({}, props, {
		__scopeToggleGroup = Object.None,
		value = Object.None,
		defaultValue = Object.None,
		onValueChange = Object.None,
	})

	local value, setValue = useControllableState({
		prop = valueProp,
		defaultProp = defaultValue,
		onChange = onValueChange,
	})

	local handleButtonActivate = React.useCallback(function(itemValue: string)
		setValue(function(prevValue)
			prevValue = prevValue or {}
			return Array.concat(prevValue, itemValue)
		end)
	end, { setValue })

	local handleButtonDeactivate = React.useCallback(function(itemValue: string)
		setValue(function(prevValue)
			prevValue = prevValue or {}
			return Array.filter(prevValue, function(val)
				return val ~= itemValue
			end)
		end)
	end, { setValue })

	return React.createElement(ToggleGroupValueProvider, {
		scope = props.__scopeToggleGroup,
		type = "multiple",
		value = value,
		onItemActivate = handleButtonActivate,
		onitemDeactivate = handleButtonDeactivate,
	}, React.createElement(ToggleGroupImpl, Object.assign({}, toggleGroupMultipleProps, { ref = forwardedRef })))
end)

type ToggleGroupContextValue = { disabled: boolean }
local ToggleGroupContext, useToggleGroupContext = createToggleGroupContext(TOGGLE_GROUP_NAME)

type ToggleGroupImplProps = {
	disabled: boolean?,
}

ToggleGroupImpl = React.forwardRef(function(props: ScopedProps<ToggleGroupImplProps>, forwardedRef)
	local __scopeToggleGroup = props.__scopeToggleGroup
	local disabled = props.disabled or false
	local toggleGroupProps = Object.assign({}, props, {
		__scopeToggleGroup = Object.None,
		disabled = Object.None,
	})

	return React.createElement(
		ToggleGroupContext,
		{ scope = __scopeToggleGroup, disabled = disabled },
		React.createElement(Primitive.Frame, Object.assign({}, toggleGroupProps, { ref = forwardedRef }))
	)
end)

local ITEM_NAME = "ToggleGroupItem"

type ToggleGroupItemProps = {
	value: string?,
	disabled: boolean?,
}

local ToggleGroupItemImpl

local ToggleGroupItem = React.forwardRef(function(props: ScopedProps<ToggleGroupItemProps>, forwardedRef)
	local __scopeToggleGroup = props.__scopeToggleGroup
	local valueContext = useToggleGroupValueContext(ITEM_NAME, __scopeToggleGroup)
	local context = useToggleGroupContext(ITEM_NAME, __scopeToggleGroup)

	local pressed = Array.includes(valueContext.value, props.value)
	local disabled = context.disabled or props.disabled
	local commonProps = Object.assign({}, props, { pressed = pressed, disabled = disabled })

	return React.createElement(ToggleGroupItemImpl, Object.assign({}, commonProps, { ref = forwardedRef }))
end)

ToggleGroupItem.displayName = ITEM_NAME

type ToggleGroupItemImplProps = {
	value: string,
}

ToggleGroupItemImpl = React.forwardRef(function(props: ScopedProps<ToggleGroupItemImplProps>, forwardedRef)
	local __scopeToggleGroup = props.__scopeToggleGroup
	local value = props.value
	local itemProps = Object.assign({}, props, {
		__scopeToggleGroup = Object.None,
		value = Object.None,
	})

	local context = useToggleGroupValueContext(ITEM_NAME, __scopeToggleGroup)

	return React.createElement(
		Toggle.Root,
		Object.assign({}, itemProps, {
			ref = forwardedRef,
			onPressedChange = function(pressed)
				local delegate = if pressed then context.onItemActivate else context.onitemDeactivate
				delegate(value)
			end,
		})
	)
end)

return {
	createToggleGroupScope = createToggleGroupScope,

	Root = ToggleGroup,
	Item = ToggleGroupItem,
}
