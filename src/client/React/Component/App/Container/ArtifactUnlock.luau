--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local ArtifactUnlock = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ArtifactUnlock")
-- Hooks
-- Contexts
local AppScreenContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Screen")
-- Types
type ItemDefinition = ArtifactUnlock.ItemDefinition
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local screen = React.useContext(AppScreenContext)
	local definitionId = if screen.Type == "ArtifactUnlock" then screen.DefinitionId else nil
	local itemDefinition = React.useMemo(function(): ItemDefinition?
		if not definitionId then
			return nil
		end
		local itemDefRes = ItemAppearanceDefinition.get(definitionId)
		if itemDefRes.IsErr then
			warn(`item-def err: {itemDefRes.Value}`)
			return nil
		end
		return itemDefRes.Value
	end, { definitionId })

	-- an artifact the library doesn't hold has no cut-scene to play, the player isn't left looking at nothing
	React.useEffect(function()
		if definitionId and not itemDefinition and ShellService.IsInitialized then
			ShellService:CloseScreen()
		end
		return function() end
	end, { definitionId :: any, itemDefinition })

	if not itemDefinition then
		return nil
	end
	-- keyed by the artifact, so the cut-scene of the next one starts over
	return e(React.Fragment, {
		key = itemDefinition.Id,
	}, {
		ArtifactUnlock = e(
			ArtifactUnlock,
			{
				Size = UDim2.fromScale(1, 1),
				ItemDefinition = itemDefinition,
				OnAction = function(action: ArtifactUnlock.ActionInfo)
					if action.Type == "Exit" then
						ShellService:CloseScreen()
					end
				end,
			} :: ArtifactUnlock.Properties
		),
	})
end
