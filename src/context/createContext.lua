local React = require(script.Parent.Parent.Parent.React)
local LuauPolyfill = require(script.Parent.Parent.Parent.LuauPolyfill)
local Object = LuauPolyfill.Object
local Error = LuauPolyfill.Error
local Array = LuauPolyfill.Array

local function createContext<ContextValueType>(rootComponentName: string, defaultContext: ContextValueType?)
	local Context = React.createContext(defaultContext :: ContextValueType | nil)

	local function Provider(props: ContextValueType & { children: React.ReactNode })
		local children, context = props.children, Object.assign({}, props, {
			children = Object.None,
		})

		local value = React.useMemo(function()
			return context
		end, Object.values(context)) :: ContextValueType

		return React.createElement(Context.Provider, { value = value }, children)
	end

	local function useContext(consumerName: string)
		local context = React.useContext(Context)
		if context then
			return context
		end

		if defaultContext ~= nil then
			return defaultContext
		end

		error(Error.new(`\`{consumerName}\` must be used within \`{rootComponentName}\``))
	end

	return Provider, useContext
end

export type Scope<C = any> = { [string]: { React.Context<C> } } | nil
type ScopeHook = (scope: Scope) -> { [string]: Scope }

type CreateScope = {
	scopeName: string,
	fn: () -> ScopeHook,
}

local composeContextScopes

local function createContextScope(scopeName: string, createContextScopeDeps_: { CreateScope }?)
	local createContextScopeDeps = if createContextScopeDeps_ ~= nil
		then createContextScopeDeps_
		else {} :: { CreateScope }

	local defaultContexts: { any } = {}

	local function createScopedContext<ContextValueType>(rootComponentName: string, defaultContext: ContextValueType?)
		local BaseContext = React.createContext(defaultContext :: ContextValueType | nil)
		local index = #defaultContexts

		defaultContexts = Object.assign({}, defaultContexts, defaultContext)

		local function Provider(props: ContextValueType & { scope: Scope<ContextValueType>, children: React.ReactNode })
			local scope, children, context =
				props.scope, props.children, Object.assign({}, props, {
					scope = Object.None,
					children = Object.None,
				})

			local Context = if scope ~= nil then scope[scopeName][index] else BaseContext

			local value = React.useMemo(function()
				return context
			end, Object.values(context)) :: ContextValueType

			return React.createElement(Context.Provider, { value = value }, children)
		end

		local function useContext(consumerName: string, scope: Scope<ContextValueType | nil>)
			local Context = if scope ~= nil then scope[scopeName][index] else BaseContext
			local context = React.useContext(Context)

			if context then
				return context
			end

			if defaultContext ~= nil then
				return defaultContext
			end

			error(Error.new(`\`{consumerName}\` must be used within \`{rootComponentName}\``))
		end

		return Provider, useContext
	end

	local createScope: CreateScope = {
		scopeName = scopeName,
		fn = function()
			local scopeContexts = Array.map(defaultContexts, function(defaultContext)
				return React.createContext(defaultContext)
			end)

			return function(scope: Scope)
				local contexts = if scope ~= nil then scope[scopeName] else scopeContexts
				return React.useMemo(function()
					return {
						[`__scope{scopeName}`] = Object.assign({}, scope, { [scopeName] = contexts }),
					}
				end, { scope, contexts })
			end
		end,
	}

	return createScopedContext, composeContextScopes(createScope, unpack(createContextScopeDeps))
end

function composeContextScopes(...: { CreateScope })
	local scopes = { ... }
	local baseScope = scopes[1]

	if #scopes == 1 then
		return baseScope
	end

	local createScope: CreateScope = {
		scopeName = baseScope.scopeName,
		fn = function()
			local scopeHooks = Array.map(scopes, function(createScope_)
				return {
					useScope = createScope_.fn(),
					scopeName = createScope_.scopeName,
				}
			end)

			return function(overrideScopes)
				local nextScopes = Array.reduce(scopeHooks, function(acc, scope)
					local useScope, scopeName = scope.useScope, scope.scopeName

					local scopeProps = useScope(overrideScopes)
					local currentScope = scopeProps[`__scope{scopeName}`]

					return Object.assign({}, acc, currentScope)
				end)

				return React.useMemo(function()
					return {
						[`__scope{baseScope.scopeName}`] = nextScopes,
					}
				end, { nextScopes })
			end
		end,
	}

	return createScope
end

return {
	createContext = createContext,
	createContextScope = createContextScope,
}
