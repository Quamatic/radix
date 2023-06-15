local src = script.Parent.Parent.Parent
local React = require(src.React)
local LuauPolyfill = require(src.LuauPolyfill)
local setTimeout, clearTimeout = LuauPolyfill.setTimeout, LuauPolyfill.clearTimeout

local useCallbackRef = require(src.Radix["use-callback-ref"])

local function useTypeaheadSearch(onSearchChange: (search: string) -> ())
	local handleSearchChange = useCallbackRef(onSearchChange)
	local searchRef = React.useRef("")
	local timerRef = React.useRef(0)

	local handleTypeaheadSearch = React.useCallback(function(key: string)
		local search = searchRef.current .. key
		handleSearchChange(search)

		local function updateSearch(value: string)
			searchRef.current = value
			clearTimeout(timerRef.current)

			if value ~= "" then
				timerRef.current = setTimeout(updateSearch, 1000, "")
			end
		end

		updateSearch(search)
	end, { handleSearchChange })

	local resetTypeahead = React.useCallback(function()
		searchRef.current = ""
		clearTimeout(timerRef.current)
	end, {})

	React.useEffect(function()
		return function()
			clearTimeout(timerRef.current)
		end
	end, {})

	return searchRef, handleTypeaheadSearch, resetTypeahead
end

return useTypeaheadSearch
