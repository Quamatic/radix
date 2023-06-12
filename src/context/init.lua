local createContext = require(script.createContext)

export type Scope<C = any> = createContext.Scope<C>
export type CreateScope = createContext.CreateScope

return {
	createContext = createContext.createContext,
	createContextScope = createContext.createContextScope,
}
