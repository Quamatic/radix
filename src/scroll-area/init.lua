local src = script.Parent.Parent
local React = require(src.React)
local ReactRoblox = require(src.ReactRoblox)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object
local Set = LuauPolyfill.Set
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
local String = LuauPolyfill.String
local clearTimeout, setTimeout = LuauPolyfill.clearTimeout, LuauPolyfill.setTimeout

type Set<T> = LuauPolyfill.Set<T>

local reactContext = require(script.Parent.context)
local createContextScope = reactContext.createContextScope
type Scope<C = any> = reactContext.Scope<C>

local Primitive = require(script.Parent.primitive)

local createCollection = require(script.Parent.collection).createCollection
local useComposedRefs = require(script.Parent["use-composed-refs"]).useComposedRefs
local useControllableState = require(script.Parent["use-controllable-state"])
local composeEventHandlers = require(script.Parent["compose-event-handlers"])

local SCROLL_AREA_NAME = "ScrollArea"

type ScopedProps<P> = P & { __scopeScrollArea: Scope? }
local createScrollAreaContext, createScrollAreaScope = createContextScope(SCROLL_AREA_NAME)

type ScrollAreaType = "auto" | "always" | "scroll" | "hover"

type ScrollAreaContextValue = {
	type: ScrollAreaType,
	scrollHideDelay: number,
	scrollArea: Frame?,
	content: Frame?,
}

local ScrollAreaProvider, useScrollAreaContext = createScrollAreaContext(SCROLL_AREA_NAME)

type ScrollAreaProps = {
	type: ScrollAreaType?,
	scrollHideDelay: number?,
}

local ScrollArea = React.forwardRef(function(props: ScopedProps<ScrollAreaProps>, forwardedRef)
	local __scopeScrollArea = props.__scopeScrollArea
	local type = props.type or "hover"
	local scrollHideDelay = props.scrollHideDelay or 600
	local scrollAreaProps = Object.assign({}, props, {
		__scopeScrollArea = Object.None,
		type = Object.None,
		scrollHideDelay = Object.None,
	})

	local composedRefs = useComposedRefs(forwardedRef)

	return React.createElement(
		ScrollAreaProvider,
		{
			scope = __scopeScrollArea,
			type = type,
			scrollHideDelay = scrollHideDelay,
		},
		React.createElement(
			Primitive.Frame,
			Object.assign({}, scrollAreaProps, {
				ref = composedRefs,
			})
		)
	)
end)

ScrollArea.displayName = SCROLL_AREA_NAME

local SCROLLBAR_NAME = "ScrollAreaScrollbar"

type ScrollAreaScrollbarProps = {
	forceMount: true?,
}

local ScrollAreaScrollbar = React.forwardRef(function(props: ScopedProps<ScrollAreaScrollbarProps>, forwardedRef) end)

ScrollAreaScrollbar.displayName = SCROLLBAR_NAME

local ScrollAreaScrollbarHover = React.forwardRef(function(props: ScopedProps<ScrollAreaScrollbarProps>, forwardedRef)
	local forceMount = props.forceMount
	local scrollbarProps = Object.assign({}, props, {
		forceMount = Object.None,
		__scopeScrollArea = Object.None,
	})

	local context = useScrollAreaContext(SCROLLBAR_NAME, props.__scopeScrollArea)
	local visible, setVisible = React.useState(false)

	React.useEffect(function()
		local scrollArea = context.scrollArea
		local hideTimer = 0

		if scrollArea then
			local function handlePointerEnter()
				clearTimeout(hideTimer)
				setVisible(true)
			end

			local function handlePointerLeave()
				hideTimer = setTimeout(setVisible, context.scrollHideDelay, false)
			end

			local connections: { RBXScriptConnection } = table.create(2)

			table.insert(connections, scrollArea.InputBegan:Connect(handlePointerEnter))
			table.insert(connections, scrollArea.InputEnded:Connect(handlePointerLeave))

			return function()
				clearTimeout(hideTimer)

				Array.forEach(connections, function(connection)
					connection:Disconnect()
				end)

				table.clear(connections)
			end
		end
	end, { context.scrollArea, context.scrollHideDelay })
end)
