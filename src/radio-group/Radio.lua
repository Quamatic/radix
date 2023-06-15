local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object
local Set = LuauPolyfill.Set
local Array = LuauPolyfill.Array

type Set<T> = LuauPolyfill.Set<T>

local reactContext = require(src.Radix.context)
local createContextScope = reactContext.createContextScope
type Scope<C = any> = reactContext.Scope<C>

local Primitive = require(script.Parent.Parent.primitive)

local createCollection = require(src.Radix.collection).createCollection
local useComposedRefs = require(src.Radix["use-composed-refs"]).useComposedRefs
local useControllableState = require(src.Radix["use-controllable-state"])
local composeEventHandlers = require(src.Radix["compose-event-handlers"])

local RADIO_NAME = "Radio"

type ScopedProps<P> = P & { __scopeRadio: Scope? }
local createRadioContext, createRadioScope = createContextScope(RADIO_NAME)

type RadioContextValue = { checked: boolean, disabled: boolean? }
local RadioProvider, useRadioContext = createRadioContext(RADIO_NAME)

type RadioProps = {
	checked: boolean?,
	disabled: boolean?,
	onCheck: (() -> ())?,
}

local Radio = React.forwardRef(function(props: ScopedProps<RadioProps>, forwardedRef)
	local __scopeRadio = props.__scopeRadio
	local checked = props.checked or false
	local disabled = props.disabled
	local onCheck = props.onCheck
	local radioProps = Object.assign({}, props, {
		__scopeRadio = Object.None,
		checked = Object.None,
		disabled = Object.None,
		onCheck = Object.None,
	})

	local _button, setButton = React.useState(nil)
	local composedRefs = useComposedRefs(forwardedRef, setButton)

	return React.createElement(
		RadioProvider,
		{
			scope = __scopeRadio,
			checked = checked,
			disabled = disabled,
		},
		React.createElement(
			Primitive.ImageButtonm,
			Object.assign({}, radioProps, {
				ref = composedRefs,
				[React.Event.Activated] = composeEventHandlers((props :: any)[React.Event.Activated], function()
					if not checked then
						onCheck()
					end
				end),
			})
		)
	)
end)

Radio.displayName = RADIO_NAME