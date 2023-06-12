local src = script.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array
local Boolean = LuauPolyfill.Boolean

local composeRefs = require(script.Parent["use-composed-refs"]).composeRefs

local isSlottable
local SlotClone

export type SlotProps = {
	children: React.ReactNode?,
}

local Slot = React.forwardRef(function(props: SlotProps, forwardedRef)
	local children, slotProps = props.children, Object.assign({}, props, {
		children = Object.None,
	})

	local childrenArray = React.Children.toArray(children)
	local slottable = Array.find(childrenArray, isSlottable)

	if Boolean(slottable) then
		local newElement = slottable.props.children :: React.ReactNode

		local newChildren = Array.map(childrenArray, function(child)
			if child == slottable then
				if React.Children.count(newElement) > 1 then
					return React.Children.only(nil :: any)
				end

				return if React.isValidElement(newElement) then newElement.props.children :: React.ReactNode else nil
			else
				return child
			end
		end)

		return React.createElement(
			SlotClone,
			Object.assign({}, slotProps, { ref = forwardedRef }),
			if React.isValidElement(newElement) then React.cloneElement(newChildren, nil, newChildren) else nil
		)
	end

	return React.createElement(SlotClone, Object.assign({}, slotProps, { ref = forwardedRef }), children)
end)

Slot.displayName = "Slot"

local function Slottable(props: { children: React.ReactNode })
	return React.createElement(React.Fragment, nil, props.children)
end

function isSlottable(child: React.ReactNode)
	return React.isValidElement(child :: any) and (child :: any).type == Slottable
end

local function mergeProps(slotProps, childProps)
	local overrideProps = table.clone(childProps)

	for propName in childProps do
		local slotPropValue = slotProps[propName]
		local childPropValue = childProps[propName]

		local isHandler = propName:match("^on[A-Z]") ~= nil
		if isHandler then
			if slotPropValue and childPropValue then
				overrideProps[propName] = function(...)
					childPropValue(...)
					slotPropValue(...)
				end
			elseif slotPropValue then
				overrideProps[propName] = slotPropValue
			end
		end
	end

	return Object.assign({}, slotProps, overrideProps)
end

type SlotCloneProps = {
	children: React.ReactNode?,
}

SlotClone = React.forwardRef(function(props: SlotCloneProps, forwardedRef)
	local children, slotProps = props.children, Object.assign({}, props, {
		children = Object.None,
	})

	if React.isValidElement(children) then
		return React.cloneElement(
			children,
			Object.assign({}, mergeProps(slotProps, children.props), {
				ref = if Boolean(forwardedRef) then composeRefs(forwardedRef, children.ref) else children.ref,
			})
		)
	end

	return if React.Children.count(children) > 1 then React.Children.only(nil :: any) else nil
end)

SlotClone.displayName = "SlotClone"

return {
	Slot = Slot,
	Slottable = Slottable,
}
