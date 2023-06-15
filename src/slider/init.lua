local GuiService = game:GetService("GuiService")
--local UserInputService = game:GetService("UserInputService")

local src = script.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local Object = LuauPolyfill.Object
local Set = LuauPolyfill.Set
local Array = LuauPolyfill.Array

type Set<T> = LuauPolyfill.Set<T>

local reactContext = require(script.Parent.context)
local createContextScope = reactContext.createContextScope
type Scope<C = any> = reactContext.Scope<C>

local Primitive = require(script.Parent.primitive)

local createCollection = require(script.Parent.collection).createCollection
local useComposedRefs = require(script.Parent["use-composed-refs"]).useComposedRefs
local useControllableState = require(script.Parent["use-controllable-state"])

local getClosestValueIndex = require(script.utils.getClosestValueIndex)
local getDecimalCount = require(script.utils.getDecimalCount)
local getNextSortedValues = require(script.utils.getNextSortedValues)
local roundValue = require(script.utils.roundValue)
local hasMinStepsBetweenValues = require(script.utils.hasMinStepsBetweenValues)
local convertValueToPercentage = require(script.utils.convertValueToPercentage)

local PAGE_KEYS = { Enum.KeyCode.PageUp, Enum.KeyCode.PageDown }
local ARROW_KEYS = { Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right }

local SLIDER_NAME = "Slider"

local Collection, useCollection, createCollectionScope = createCollection(SLIDER_NAME)

type ScopedProps<P> = P & { __scopeSlider: Scope }
local createSliderContext, createSliderScope = createContextScope(SLIDER_NAME, {
	createCollectionScope,
})

type SliderContextValue = {
	disabled: boolean?,
	min: number,
	max: number,
	values: { number },
	valueIndexToChangeRef: { current: number },
	thumbs: Set<Frame>,
	--orientation: SliderProps['orientation'];
}

local SliderProvider, useSliderContext = createSliderContext(SLIDER_NAME)

type SliderProps = {
	name: string?,
	disabled: boolean?,
	--orientation?: React.AriaAttributes['aria-orientation'];
	--dir?: Direction;
	min: number?,
	max: number?,
	step: number?,
	minStepsBetweenThumbs: number?,
	value: { number }?,
	defaultValue: { number }?,
	onValueChange: ((value: { number }) -> ())?,
	onValueCommit: ((value: { number }) -> ())?,
	inverted: boolean?,
}

local SliderOrientation

local Slider = React.forwardRef(function(props: ScopedProps<SliderProps>, forwardedRef)
	local __scopeSlider = props.__scopeSlider
	local name = props.name
	local min = props.min or 0
	local max = props.max or 0
	local step = props.step or 1
	local disabled = props.disabled or false
	local minStepsBetweenThumbs = props.minStepsBetweenThumbs or 0
	local defaultValue = props.defaultValue or { min }
	local value = props.value
	local onValueChange = props.onValueChange or function() end
	local onValueCommit = props.onValueCommit or function() end
	local inverted = props.inverted or false
	local sliderProps = Object.assign({}, props, {
		__scopeSlider = Object.None,
		name = Object.None,
		min = Object.None,
		max = Object.None,
		step = Object.None,
		disabled = Object.None,
		minStepsBetweenThumbs = Object.None,
		defaultValue = Object.None,
		value = Object.None,
		onValueChange = Object.None,
		onValueCommit = Object.None,
		inverted = Object.None,
	})

	local slider, setSlider = React.useState(nil)
	local composedRefs = useComposedRefs(forwardedRef, setSlider)
	local thumbRefs = React.useRef(Set.new() :: Set<Frame>)
	local valueIndexToChangeRef = React.useRef(0)

	local values, setValues = useControllableState({
		prop = value,
		defaultProp = defaultValue,
		onChange = function(val)
			local thumbs = table.clone(thumbRefs.current)
			thumbs[valueIndexToChangeRef.current].focus()
			onValueChange(val)
		end,
	})

	local valuesBeforeSliderStartRef = React.useRef(values)

	local function updateValues(val: number, atIndex: number, commit: boolean?)
		local decimalCount = getDecimalCount(val)
		local snapToStep = roundValue(math.round((val - min) / step) * step + min, decimalCount)
		local nextValue = math.clamp(snapToStep, min, max)

		setValues(function(prevValues)
			prevValues = prevValues or {}
			local nextValues = getNextSortedValues(prevValues, nextValue, atIndex)
			if hasMinStepsBetweenValues(values, minStepsBetweenThumbs * step) then
				valueIndexToChangeRef.current = Array.indexOf(nextValues, nextValue)

				local hasChanged = tostring(nextValues) ~= tostring(prevValues)
				if hasChanged and commit then
					onValueCommit(nextValues)
				end

				return if hasChanged then nextValues else prevValues
			else
				return prevValues
			end
		end)
	end

	local function handleSliderStart(val: number)
		local closestIndex = getClosestValueIndex(values, value)
		updateValues(val, closestIndex)
	end

	local function handleSlideMove(val: number)
		updateValues(val, valueIndexToChangeRef.current)
	end

	local function handleSlideEnd(val: number)
		local prevValue = valuesBeforeSliderStartRef.current[valueIndexToChangeRef.current]
		local nextValue = values[valueIndexToChangeRef.current]

		if nextValue ~= prevValue then
			onValueCommit(values)
		end
	end

	return React.createElement(
		SliderProvider,
		{
			scope = __scopeSlider,
			disabled = disabled,
			min = min,
			max = max,
			valueIndexToChangeRef = valueIndexToChangeRef,
			thumbs = thumbRefs.current,
			values = values,
		},
		React.createElement(
			Collection.Provider,
			{ scope = __scopeSlider },
			React.createElement(
				Collection.Slot,
				{ scope = __scopeSlider },
				React.createElement(
					SliderOrientation,
					Object.assign({}, sliderProps, {
						ref = composedRefs,
						min = min,
						max = max,
						inverted = inverted,
						onSlideStart = if disabled then nil else handleSliderStart,
						onSlideMove = if disabled then nil else handleSlideMove,
						onSlideEnd = if disabled then nil else handleSlideEnd,
						onHomeKeyDown = function()
							if not disabled then
								updateValues(min, 0, true)
							end
						end,
						onEndKeyDown = function()
							if not disabled then
								updateValues(max, #values, true)
							end
						end,
						onStepKeyDown = function(input: InputObject, direction: number)
							if not disabled then
								local isPageKey = Array.includes(PAGE_KEYS, input.KeyCode)
								local isSkipKey = isPageKey
									or (
										input:IsModifierKeyDown(Enum.ModifierKey.Shift)
										and Array.includes(ARROW_KEYS, input.KeyCode)
									)
								local multiplier = if isSkipKey then 10 else 1
								local atIndex = valueIndexToChangeRef.current
								local val = values[atIndex]
								local stepInDirection = step * multiplier * direction
								updateValues(val + stepInDirection, atIndex, true)
							end
						end,
					})
				)
			)
		)
	)
end)

Slider.displayName = SLIDER_NAME

local SliderOrientationProvider, useSliderOrientationContext = createSliderContext(SLIDER_NAME)

SliderOrientation = React.forwardRef(function(props, forwardedRef) end)

local RANGE_NAME = "SliderRange"

type SliderRangeProps = {}

local SliderRange = React.forwardRef(function(props: ScopedProps<SliderRangeProps>, forwardedRef)
	local __scopeSlider = props.__scopeSlider
	local rangeProps = Object.assign({}, props, { __scopeSlider = Object.None })

	local context = useSliderContext(RANGE_NAME, __scopeSlider)
	local orientation = useSliderOrientationContext(RANGE_NAME, __scopeSlider)
	local ref = React.useRef(nil :: Frame?)
	local composedRefs = useComposedRefs(forwardedRef, ref)
	local valuesCount = #context.values
	local percentages = Array.map(context.values, function(value)
		return convertValueToPercentage(value, context.min, context.max)
	end)

	local offsetStart = if valuesCount > 1 then math.min(unpack(percentages)) else 0
	local offsetEnd = 100 - math.max(unpack(percentages))

	return React.createElement(
		"Frame",
		Object.assign({}, rangeProps, {
			Position = UDim2.fromScale(offsetStart, offsetEnd),
			ref = composedRefs,
		})
	)
end)

SliderRange.displayName = RANGE_NAME

local THUMB_NAME = "SliderThumb"

type SliderThumbProps = {}

local SliderThumbImpl

local SliderThumb = React.forwardRef(function(props: ScopedProps<SliderThumbProps>, forwardedRef)
	local getItems = useCollection(props.__scopeSlider)
	local thumb, setThumb = React.useState(nil :: GuiObject?)
	local composedRefs = useComposedRefs(forwardedRef, setThumb)

	local index = React.useMemo(function()
		return if thumb
			then Array.findIndex(getItems(), function(item)
				return item.ref.current == thumb
			end)
			else -1
	end, { getItems, thumb })

	return React.createElement(SliderThumbImpl, Object.assign({}, props, { ref = composedRefs, index = index }))
end)

type SliderThumbImplProps = {
	index: number,
}

SliderThumbImpl = React.forwardRef(function(props: ScopedProps<SliderThumbImplProps>, forwardedRef)
	local __scopeSlider, index, thumbProps =
		props.__scopeSlider, props.index, Object.assign({}, props, {
			__scopeSlider = Object.None,
			index = Object.None,
		})

	local context = useSliderContext(THUMB_NAME, __scopeSlider)
	local thumb, setThumb = React.useState(nil :: GuiObject?)
	local composedRefs = useComposedRefs(forwardedRef, setThumb)

	local value = context.thumbs[index] :: number?
	local percent = if value == nil then 0 else convertValueToPercentage(value, context.min, context.max)

	React.useImperativeHandle(forwardedRef, function()
		return {
			focus = function()
				GuiService:Select(forwardedRef)
			end,
		}
	end)

	React.useEffect(function()
		context.thumbs:add(thumb)
		return function()
			context.thumbs:delete(thumb)
		end
	end, { thumb, context.thumbs })

	return React.createElement(
		"Frame",
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(percent, 0.5),
			BackgroundTransparency = 1,
		},
		React.createElement(
			Collection.ItemSlot,
			{ scope = __scopeSlider },
			React.createElement(
				Primitive.Frame,
				Object.assign({}, thumbProps, {
					ref = composedRefs,
					[React.Event.SelectionGained] = function()
						context.valueIndexToChangeRef.current = index
					end,
				})
			)
		)
	)
end)

return {
	Root = Slider,
	Thumb = SliderThumb,
	Range = SliderRange,
}
