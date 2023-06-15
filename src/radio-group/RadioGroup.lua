local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object

local reactContext = require(src.Radix.context)
local createContextScope = reactContext.createContextScope
type Scope<C = any> = reactContext.Scope<C>

local useComposedRefs = require(src.Radix["use-composed-refs"]).useComposedRefs
local useControllableState = require(src.Radix["use-controllable-state"])

local Radio_ = require(script.Parent.Radio)
local Radio, RadioIndicator, createRadioScope = Radio_.Radio, Radio_.RadioIndicator, Radio_.createRadioScope

type RadioProps = Radio_.RadioProps
type RadioIndicatorProps = Radio_.RadioIndicatorProps

local RADIO_GROUP_NAME = "RadioGroup"

type ScopedProps<P> = P & { __scopeRadioGroup: Scope? }
local createRadioGroupContext, createRadioGroupScope = createContextScope(RADIO_GROUP_NAME, {
	createRadioScope,
})

local useRadioScope = createRadioScope()

type RadioGroupContextValue = {
	name: string?,
	disabled: boolean,
	value: string?,
	onValueChange: (value: string) -> (),
}

local RadioGroupProvider, useRadioGroupContext = createRadioGroupContext(RADIO_GROUP_NAME)

export type RadioGroupProps = {
	disabled: boolean?,
	defaultValue: string?,
	value: string?,
	onValueChange: ((value: string) -> ())?,
}

local RadioGroup = React.forwardRef(function(props: ScopedProps<RadioGroupProps>, forwardedRef)
	local __scopeRadioGroup = props.__scopeRadioGroup
	local disabled = props.disabled
	local defaultValue = props.defaultValue
	local valueProp = props.value
	local onValueChange = props.onValueChange
	local groupProps = Object.assign({}, props, {
		__scopeRadioGroup = Object.None,
		disabled = Object.None,
		defaultValue = Object.None,
		value = Object.None,
		onValueChange = Object.None,
	})

	local value, setValue = useControllableState({
		prop = valueProp,
		defaultProp = defaultValue,
		onChange = onValueChange,
	})

	return React.createElement(
		RadioGroupProvider,
		{
			scope = __scopeRadioGroup,
			name = "",
			disabled = disabled,
			value = value,
			onValueChange = setValue,
		},
		React.createElement(
			"Frame",
			Object.assign({}, groupProps, {
				ref = forwardedRef,
			})
		)
	)
end)

RadioGroup.displayName = RADIO_GROUP_NAME

local ITEM_NAME = "RadioGroupItem"

export type RadioGroupItemProps = RadioProps & {
	value: string,
}

local RadioGroupItem = React.forwardRef(function(props: ScopedProps<RadioGroupItemProps>, forwardedRef)
	local __scopeRadioGroup = props.__scopeRadioGroup
	local disabled = props.disabled
	local itemProps = Object.assign({}, props, {
		__scopeRadioGroup = Object.None,
		disabled = Object.None,
	})

	local context = useRadioGroupContext(ITEM_NAME, __scopeRadioGroup)
	local isDisabled = context.disabled or disabled
	local radioScope = useRadioScope(__scopeRadioGroup)
	local composedRefs = useComposedRefs(forwardedRef)
	local checked = context.value == itemProps.value

	return React.createElement(
		Radio,
		Object.assign(
			{
				disabled = isDisabled,
				checked = checked,
			},
			radioScope,
			itemProps,
			{
				ref = composedRefs,
				onCheck = function()
					context.onValueChange(itemProps.value)
				end,
			}
		)
	)
end)

RadioGroupItem.displayName = ITEM_NAME

local INDICATOR_NAME = "RadioGroupIndicator"

export type RadioGroupIndicatorProps = RadioIndicatorProps & {}

local RadioGroupIndicator = React.forwardRef(function(props: ScopedProps<RadioGroupIndicatorProps>, forwardedRef)
	local __scopeRadioGroup, indicatorProps =
		props.__scopeRadioGroup, Object.assign({}, props, {
			__scopeRadioGroup = Object.None,
		})

	local radioScope = useRadioScope(__scopeRadioGroup)

	return React.createElement(RadioIndicator, Object.assign({}, radioScope, indicatorProps, { ref = forwardedRef }))
end)

RadioGroupIndicator.displayName = INDICATOR_NAME

return {
	createRadioGroupScope = createRadioGroupScope,
	Root = RadioGroup,
	Item = RadioGroupItem,
	Indicator = RadioGroupIndicator,
}
