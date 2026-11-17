--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Contexts
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
-- Types
export type Character = SessionCharactersContext.Character
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(index: number?): Character?
	local characters = React.useContext(SessionCharactersContext)
	if not index or #characters == 0 then
		return nil
	end
	return characters[(index - 1) % #characters + 1]
end
