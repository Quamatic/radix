local src = script.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object

local reactContext = require(src.Radix.context)
local createContextScope = reactContext.createContextScope

local Primitive = require(src.Radix.primitive)
local Presence = require(src.Radix.presence)
local PortalPrimitive = require(src.Radix.portal)

local useComposedRefs = require(src.Radix["use-composed-refs"]).useComposedRefs
local useControllableState = require(src.Radix["use-controllable-state"])

type Scope<C = any> = reactContext.Scope<C>

local DIALOG_NAME = "Dialog"

export type ScopedProps<P> = P & { __scopeDialog: Scope? }
local createDialogContext, createDialogScope = createContextScope(DIALOG_NAME)

export type DialogContextValue = {}
local DialogProvider, useDialogContext = createDialogContext()

export type DialogProps = {
	open: boolean?,
	defaultOpen: boolean?,
	onOpenChange: ((open: boolean) -> ())?,
	modal: boolean?,
	children: React.ReactNode?,
}

local Dialog: React.FC<ScopedProps<DialogProps>> = function(props)
	local __scopeDialog = props.__scopeDialog
	local openProps = props.open
	local defaultOpen = props.defaultOpen
	local onOpenChange = props.onOpenChange
	local modal = props.modal or true
	local children = props.children

	local triggerRef = React.useRef(nil)
	local contentRef = React.useRef(nil)

	local open, setOpen = useControllableState({
		prop = openProps,
		defaultProp = defaultOpen,
		onChange = onOpenChange,
	})

	return React.createElement(DialogProvider, {
		scope = __scopeDialog,
		triggerRef = triggerRef,
		contentRef = contentRef,
		open = open,
		onOpenChange = setOpen,
		onOpenToggle = React.useCallback(function()
			setOpen(function(prevOpen)
				return not prevOpen
			end)
		end, { setOpen }),
		modal = modal,
	}, children)
end

local TRIGGER_NAME = "DialogTrigger"

type DialogTriggerProps = {}

local DialogTrigger = React.forwardRef(function(props: ScopedProps<DialogTriggerProps>, forwardedRef)
	local __scopeDialog = props.__scopeDialog
	local triggerProps = Object.assign({}, props, { __scopeDialog = Object.None })

	local context = useDialogContext(TRIGGER_NAME, __scopeDialog)
	local composedTriggerRef = useComposedRefs(forwardedRef, context.triggerRef)

	return React.createElement(
		Primitive.TextButton,
		Object.assign({}, triggerProps, {
			ref = composedTriggerRef,
			[React.Event.Activated] = context.onOpenToggle,
		})
	)
end)

DialogTrigger.displayName = TRIGGER_NAME

local PORTAL_NAME = "DialogPortal"

type PortalContextValue = { forceMount: true? }
local PortalProvider, usePortalContext = createDialogContext(PORTAL_NAME, { forceMount = nil })

type DialogPortalProps = {
	container: any?,
	forceMount: true?,
	children: React.ReactNode?,
}

local DialogPortal: React.FC<ScopedProps<DialogPortalProps>> = function(props)
	local __scopeDialog, forceMount, container, children =
		props.__scopeDialog, props.forceMount, props.container, props.children

	local context = useDialogContext(PORTAL_NAME, __scopeDialog)

	return React.createElement(
		PortalProvider,
		{ scope = __scopeDialog, forceMount = forceMount },
		React.Children.map(children, function(child)
			-- TODO: PortalPrimitive
			return React.createElement(Presence, {
				present = forceMount or context.open,
			} :: any, React.createElement(PortalPrimitive, { asChild = true, container = container }, child))
		end)
	)
end

return {
	Root = Dialog,
	Trigger = DialogTrigger,
	Portal = DialogPortal,
}
