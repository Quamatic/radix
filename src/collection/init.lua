local src = script.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Map = LuauPolyfill.Map
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array

type Map<K, V> = LuauPolyfill.Map<K, V>

local Slot = require(script.Parent.slot).Slot
local createContextScope = require(script.Parent.context).createContextScope
local useComposedRefs = require(script.Parent["use-composed-refs"]).useComposedRefs

type RefObject<T> = {
	current: T?,
}

type CollectionElement = GuiObject
type CollectionProps = {
	scope: any,
	children: React.ReactNode?,
}

local function querySelectorAll(node: GuiObject, selector: string)
	local nodeList: { GuiObject } = {}

	for _, descendant in node:GetDescendants() do
		if descendant:GetAttribute(selector) ~= nil then
			table.insert(nodeList, descendant)
		end
	end

	return nodeList
end

local function createCollection<ItemElement, ItemData>(name: string)
	local PROVIDER_NAME = name .. "CollectionProvider"
	local createCollectionContext, createCollectionScope = createContextScope(PROVIDER_NAME)

	type ContextValue = {
		collectionRef: RefObject<CollectionElement>,
		itemMap: ItemMap,
	}

	type ItemMap = Map<RefObject<ItemElement>, { ref: RefObject<ItemElement> } & ItemData>

	local CollectionProviderImpl, useCollectionContext =
		createCollectionContext(PROVIDER_NAME, { collectionRef = { current = nil }, itemMap = Map.new() })

	local CollectionProvider: React.FC<{ children: React.ReactNode?, scope: any }> = function(props)
		local scope, children = props.scope, props.children
		local ref = React.useRef(nil :: CollectionElement?)
		local itemMap = React.useRef(Map.new() :: ItemMap).current

		return React.createElement(CollectionProviderImpl, {
			scope = scope,
			itemMap = itemMap,
			collectionRef = ref,
		}, children)
	end

	local COLLECTION_SLOT_NAME = name .. "CollectionSlot"

	local CollectionSlot = React.forwardRef(function(props: CollectionProps, forwardedRef)
		local scope, children = props.scope, props.children
		local context = useCollectionContext(COLLECTION_SLOT_NAME, scope)
		local composedRefs = useComposedRefs(forwardedRef, context.collectionRef)

		return React.createElement(Slot, { ref = composedRefs }, children)
	end)

	CollectionSlot.displayName = COLLECTION_SLOT_NAME

	local ITEM_SLOT_NAME = name .. "CollectionItemSlot"
	local ITEM_DATA_ATTR = "data-radix-collection-item"

	type CollectionItemSlotProps = ItemData & {
		children: React.ReactNode,
		scope: any,
	}

	local CollectionItemSlot = React.forwardRef(function(props: CollectionItemSlotProps, forwardedRef)
		local scope, children, itemData =
			props.scope, props.children, Object.assign({}, props, {
				scope = Object.None,
				children = Object.None,
			})

		local ref = React.useRef(nil :: ItemElement?)
		local composedRefs = useComposedRefs(forwardedRef, ref)
		local context = useCollectionContext(ITEM_SLOT_NAME, scope)

		React.useEffect(function()
			ref.current:SetAttribute(ITEM_DATA_ATTR, "")

			context.itemMap:set(ref, Object.assign({ ref = ref }, itemData))
			return function()
				context.itemMap:delete(ref)
			end
		end)

		return React.createElement(Slot, { ref = composedRefs }, children)
	end)

	CollectionItemSlot.displayName = ITEM_SLOT_NAME

	local function useCollection(scope: any)
		local context = useCollectionContext(name .. "CollectionConsumer", scope)

		local getItems = React.useCallback(function()
			local collectionNode = context.collectionRef.current
			if collectionNode == nil then
				return {}
			end

			local orderedNodes = Array.from(querySelectorAll(collectionNode, ITEM_DATA_ATTR))
			local items = Array.from(context.itemMap:values())
			local orderedItems = Array.sort(items, function(a, b)
				return Array.indexOf(orderedNodes, a.ref.current) - Array.indexOf(orderedNodes, b.ref.current)
			end)

			return orderedItems
		end, { context.collectionRef, context.itemMap })

		return getItems
	end

	return { Provider = CollectionProvider, Slot = CollectionSlot, ItemSlot = CollectionItemSlot },
		useCollection,
		createCollectionScope
end

return {
	createCollection = createCollection,
}
