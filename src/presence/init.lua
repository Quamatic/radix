local src = script.Parent.Parent
local React = require(src.React)

local useStateMachine = require(script.useStateMachine)

type PresenceProps = {
	children: React.ReactElement<any, any> | ((props: { present: boolean }) -> React.ReactElement<any, any>),
	present: boolean,
}

local Presence: React.FC<PresenceProps> = function(props)
	local present, children = props.present, props.children

	return React.createElement("Frame")
end

return Presence
