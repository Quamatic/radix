local src = script.Parent.Parent

local React = require(src.React)
local ReactFloating = require(src.React) :: any -- TODO: Install FloatingUI
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object
local Boolean = LuauPolyfill.Boolean

local Primitive = require(script.Parent.primitive)
local reactContext = require(script.Parent.context)
local createContextScope = reactContext.createContextScope

local useComposedRefs = require(script.Parent["use-composed-refs"])

type Scope<C = any> = reactContext.Scope<C>

local POPPER_NAME = "Popper"

type ScopedProps<P> = P & { __scopePopper: Scope }
local createPopperContext, createPopperScope = createContextScope(POPPER_NAME)

type PopperContextValue = {}
local PopperProvider, usePopperContext = createPopperContext(POPPER_NAME)

type PopperProps = {
	children: React.ReactNode?,
}

local Popper: React.FC<ScopedProps<PopperProps>> = function(props)
	local __scopeProvider, children = props.__scopePopper, props.children
	local anchor, setAnchor = React.useState(nil)

	return React.createElement(PopperProvider, {
		scope = __scopeProvider,
		anchor = anchor,
		onAnchorChange = setAnchor,
	}, children)
end

--Popper.displayName = POPPER_NAME

local ANCHOR_NAME = "PopperAnchor"

type PopperAnchorProps = {
	virtualRef: React.Ref<GuiObject>?,
}

local PopperAnchor = React.forwardRef(function(props: ScopedProps<PopperAnchorProps>, forwardedRef)
	local __scopePopper, virtualRef, anchorProps =
		props.__scopePopper, props.virtualRef, Object.assign({}, props, {
			__scopePopper = Object.None,
			virtualRef = Object.None,
		})

	local context = usePopperContext(ANCHOR_NAME, __scopePopper)
	local ref = React.useRef(nil)

	React.useEffect(function()
		context.onAnchorChange(virtualRef.current or ref.current)
	end)

	return if Boolean(virtualRef)
		then nil
		else React.createElement(Primitive.Frame, Object.assign({}, anchorProps, { ref = ref }))
end)

PopperAnchor.displayName = ANCHOR_NAME

local CONTENT_NAME = "PopperConent"

type PopperContentContextValue = {}
local PopperContentProvider, useContentContext = createContextScope(CONTENT_NAME)

type PopperContentProps = {
	side: string?,
	sideOffset: number?,
	align: string?,
	alignOffset: number?,
	arrowPadding: number?,
	avoidCollisions: boolean?,
	sticky: "partial" | "always"?,
	hideWhenDetached: boolean?,
	updatePositionStrategy: "optimized" | "always"?,
	onPlaced: (() -> ())?,
}

local PopperContent = React.forwardRef(function(props: ScopedProps<PopperContentProps>, forwardedRef)
	local __scopePopper = props.__scopePopper
	local side = props.side or "bottom"
	local sideOffset = props.sideOffset or 0
	local align = props.align or "center"
	local alignOffset = props.alignOffset or 0
	local arrowPadding = props.arrowPadding or 0
	local avoidCollisions = props.avoidCollisions or true
	local sticky = props.sticky or "partial"
	local hideWhenDetached = props.hideWhenDetached or false
	local updatePositionStrategy = props.updatePositionStrategy or "optimized"
	local onPlaced = props.onPlaced
	local contentProps = Object.assign({}, props, {
		side = Object.None,
		sideOffset = Object.None,
		align = Object.None,
		alignOffset = Object.None,
		arrowPadding = Object.None,
		avoidCollisions = Object.None,
		sticky = Object.None,
		hideWhenDetached = Object.None,
		updatePositionStrategy = Object.None,
		onPlaced = Object.None,
	})

	local context = usePopperContext(CONTENT_NAME, __scopePopper)

	local content, setContent = React.useState(nil)
	local composedRefs = useComposedRefs(forwardedRef, function(node)
		return setContent(node)
	end :: any)

	local arrow, setArrow = React.useState(nil)

	local desiredPlacement = side .. (if align ~= "center" then "-" .. align else "")
	local collisionPadding = 0

	local detectOverflowOptions = {
		padding = collisionPadding,
	}

	local floating = ReactFloating.useFloating({
		placement = desiredPlacement,
		whileElementsMounted = function(...)
			local cleanup = ReactFloating.autoUpdate(..., {
				animationFrame = updatePositionStrategy == "always",
			})

			return cleanup
		end,
		elements = {
			reference = context.anchor,
		},
		middleware = {
			ReactFloating.offset({
				mainAxis = sideOffset,
				alignmentAxis = alignOffset,
			}),
			avoidCollisions and ReactFloating.shift(Object.assign({
				mainAxis = true,
				crossAxis = false,
				limiter = if sticky == "partial" then ReactFloating.limitShift() else nil,
			}, detectOverflowOptions)),
			avoidCollisions and ReactFloating.flip(table.clone(detectOverflowOptions)),
			arrow and ReactFloating.arrow({ element = arrow, padding = arrowPadding }),
			hideWhenDetached
				and ReactFloating.hide(Object.assign({ strategy = "referenceHidden" }, detectOverflowOptions)),
		},
	})

	return React.createElement(
		"Frame",
		Object.assign({
			ref = floating.refs.setFloating,
		}, floating.floatingStyles),
		React.createElement(
			PopperContentProvider,
			{
				scope = __scopePopper,
				placedSide = 1,
			},
			React.createElement(
				"Frame",
				Object.assign({}, contentProps, {
					ref = composedRefs,
					BackgroundTransparency = 1,
				})
			)
		)
	)
end)

PopperContent.displayName = CONTENT_NAME

return {
	Root = Popper,
	Anchor = PopperAnchor,
	Content = PopperContent,
	createPopperScope = createPopperScope,
}
