local src = script.Parent.Parent
local React = require(src.React)
local ReactRoblox = require(src.ReactRoblox)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object
local Set = LuauPolyfill.Set
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
local String = LuauPolyfill.String

type Set<T> = LuauPolyfill.Set<T>

local reactContext = require(script.Parent.context)
local createContextScope = reactContext.createContextScope
type Scope<C = any> = reactContext.Scope<C>

local Primitive = require(script.Parent.primitive)

local createCollection = require(script.Parent.collection).createCollection
local useComposedRefs = require(script.Parent["use-composed-refs"]).useComposedRefs
local useControllableState = require(script.Parent["use-controllable-state"])
local composeEventHandlers = require(script.Parent["compose-event-handlers"])

local PopperPrimitive = require(script.Parent.popper)
local createPopperScope = PopperPrimitive.createPopperScope

local useTypeaheadSearch = require(script.useTypeaheadSearch)
local findNextItem = require(script.utils.findNextItem)

local SELECT_NAME = "Select"

type ItemData = {
	value: string,
	disabled: boolean,
	textValue: string,
}

local Collection, useCollection, createCollectionScope = createCollection(SELECT_NAME)

type ScopedProps<P> = P & { __scopeSelect: Scope }
local createSelectContext, createSelectScope = createContextScope(SELECT_NAME, {
	createCollectionScope,
	createPopperScope,
})

local usePopperScope = createPopperScope()

type SelectContextValue = {
	trigger: GuiObject?,
	onTriggerChange: (node: GuiObject?) -> (),
	value: string?,
	onValueChange: (value: string) -> (),
	open: boolean,
	onOpenChange: (open: boolean) -> (),
	disabled: boolean?,
}

local SelectProvider, useSelectContext = createSelectContext(SELECT_NAME)

type SelectProps = {
	children: React.ReactNode?,
	value: string?,
	defaultValue: string?,
	onValueChange: ((value: string) -> ())?,
	open: boolean?,
	defaultOpen: boolean?,
	onOpenChange: ((open: boolean) -> ())?,
	autoComplete: string?,
	disabled: boolean?,
}

local Select: React.FC<ScopedProps<SelectProps>> = function(props)
	local __scopeSelect = props.__scopeSelect
	local children = props.children
	local openProp = props.open
	local defaultOpen = props.defaultOpen
	local onOpenChange = props.onOpenChange
	local valueProp = props.value
	local defaultValue = props.defaultValue
	local onValueChange = props.onValueChange
	local autoComplete = props.autoComplete
	local disabled = props.disabled

	local popperScope = usePopperScope(__scopeSelect)

	local open, setOpen = useControllableState({
		prop = openProp,
		defaultProp = defaultOpen,
		onChange = onOpenChange,
	})

	local value, setValue = useControllableState({
		prop = valueProp,
		defaultProp = defaultValue,
		onChange = onValueChange,
	})

	return React.createElement(
		PopperPrimitive.Root,
		popperScope,
		React.createElement(SelectProvider, {
			scope = __scopeSelect,
		}, React.createElement(Collection.Provider, { scope = __scopeSelect }, children))
	)
end

local TRIGGER_NAME = "SelectTrigger"

type SelectTriggerProps = {
	disabled: boolean?,
}

local SelectTrigger = React.forwardRef(function(props: ScopedProps<SelectTriggerProps>, forwardedRef)
	local __scopeSelect = props.__scopeSelect
	local disabled = props.disabled or false
	local triggerProps = Object.assign({}, props, {
		__scopeSelect = Object.None,
		disabled = Object.None,
	})

	local popperScope = usePopperScope(__scopeSelect)
	local context = useSelectContext(TRIGGER_NAME, __scopeSelect)
	local isDisabled = context.disabled or disabled
	local composedRefs = useComposedRefs(forwardedRef, context.onTriggerChange)
	local getItems = useCollection(__scopeSelect)

	local searchRef, handleTypeaheadSearch, resetTypeahead = useTypeaheadSearch(function(search)
		local enabledItems = Array.filter(getItems(), function(item)
			return not item.disabled
		end)

		local currentItem = Array.find(enabledItems, function(item)
			return item.value == context.value
		end)

		local nextItem = findNextItem(enabledItems, search, currentItem)
		if nextItem ~= nil then
			context.onValueChange(nextItem.value)
		end
	end)

	local function handleOpen()
		if not isDisabled then
			context.onOpenChange(true)
			resetTypeahead()
		end
	end

	return React.createElement(
		PopperPrimitive.Anchor,
		Object.assign({ asChild = true }, popperScope),
		React.createElement(
			Primitive.TextBox,
			Object.assign({}, triggerProps, {
				ref = composedRefs,
				[React.Event.Activated] = composeEventHandlers(
					(props :: any)[React.Event.Activated],
					function(target: TextBox)
						-- Capture focus by using a fake TextBox
						target:CaptureFocus()
						handleOpen()
					end
				),
				[React.Change.Text] = composeEventHandlers((props :: any)[React.Change.Text], function(target: TextBox)
					handleTypeaheadSearch(target.Text)
				end),
			})
		)
	)
end)

SelectTrigger.displayName = TRIGGER_NAME

local ICON_NAME = "SelectIcon"

type SelectIconProps = {
	children: React.ReactNode?,
}

local SelectIcon = React.forwardRef(function(props: ScopedProps<SelectIconProps>, forwardedRef)
	local __scopeSelect = props.__scopeSelect
	local children = props.children
	local iconProps = Object.assign({}, props, {
		__scopeSelect = Object.None,
		children = Object.None,
	})

	return React.createElement(
		"TextLabel",
		Object.assign({}, iconProps, { Text = "▼", ref = forwardedRef }),
		children
	)
end)

SelectIcon.displayName = ICON_NAME

local CONTENT_NAME = "SelectContent"

type SelectContentProps = {}

local SelectContentImpl

local SelectContent = React.forwardRef(function(props: ScopedProps<SelectContentProps>, forwardedRef)
	local context = useSelectContext(CONTENT_NAME, props.__scopeSelect)

	if not context.open then
		return ReactRoblox.createPortal(React.createElement(""), Instance.new("Frame"))
	end

	return React.createElement(SelectContentImpl, Object.assign({}, props, { ref = forwardedRef }))
end)

SelectContent.displayName = CONTENT_NAME

type SelectContentContextValue = {}

local SelectContentProvider, useSelectContentContext = createSelectContext(CONTENT_NAME)

SelectContentImpl = React.forwardRef(function(props, forwardedRef) end)

local ITEM_NAME = "SelectItem"

type SelectItemContextValue = {
	value: string,
	disabled: boolean,
	textId: string,
	isSelected: boolean,
	onItemTextChange: (node: GuiObject?) -> (),
}
local SelectItemContextProvider, useSelectItemContext = createSelectContext(ITEM_NAME)

type SelectItemProps = {
	value: string,
	disabled: boolean?,
	textValue: string?,
}

local SelectItem = React.forwardRef(function(props: ScopedProps<SelectItemProps>, forwardedRef)
	local __scopeSelect = props.__scopeSelect
	local value = props.value
	local disabled = props.disabled or false
	local textValueProp = props.textValue
	local itemProps = Object.assign({}, props, {
		__scopeSelect = Object.None,
		value = Object.None,
		disabled = Object.None,
		textValue = Object.None,
	})

	local context = useSelectContext(SELECT_NAME, __scopeSelect)
	local isSelected = context.value == value

	local textValue, setTextValue = React.useState(textValueProp or "")
	local isFocused, setIsFocused = React.useState(false)

	local composedRefs = useComposedRefs(forwardedRef, function(node)
		return context.itemRefCallback ~= nil and context.itemRefCallback(node, value, disabled)
	end)

	local function handleSelect()
		if not disabled then
			context.onValueChange(value)
			context.onOpenChange(false)
		end
	end

	if value == "" then
		error(
			Error.new(
				"A <Select.Item /> must have a value prop that is not an empty string. This is because the Select value can be set to an empty string to clear the selection and show the placeholder."
			)
		)
	end

	return React.createElement(
		SelectItemContextProvider,
		{
			scope = __scopeSelect,
			value = value,
			disabled = disabled,
			isSelected = isSelected,
			onItemTextChange = React.useCallback(function(node)
				setTextValue(function(prevTextValue)
					return prevTextValue or String.trim(if node ~= nil then node.Text else "")
				end)
			end, {}),
		},
		React.createElement(
			Collection.ItemSlot,
			{
				scope = __scopeSelect,
				value = value,
				disabled = disabled,
				textValue = textValue,
			},
			React.createElement(
				Primitive.TextButton,
				Object.assign({}, itemProps, {
					ref = composedRefs,
					[React.Event.Activated] = handleSelect,
					[React.Event.SelectionGained] = nil,
					[React.Event.SelectionLost] = nil,
				})
			)
		)
	)
end)

SelectItem.displayName = ITEM_NAME

return {
	Root = Select,
	Item = SelectItem,
	Trigger = SelectTrigger,
}
