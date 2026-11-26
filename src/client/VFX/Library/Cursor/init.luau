--!strict
-- Services
local UserInputService = game:GetService("UserInputService")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Cursor
-- one pointer that's on
type Entry = {
	Url: string,
}
-- Constants
-- Variables
-- every pointer that's on, in the order they came on: the last is the one that shows
local Entries: { Entry } = {}
-- what the mouse pointed with before the first of them
local InitialIcon = ""
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Cursor, function(props: Properties, scope: ClientScope)
	-- what somebody else holds isn't this machine's to point with
	if not scope.IsOwner then
		return function() end
	end
	local entry: Entry = { Url = VFXAssetDefinition.getDecal(props.Image).TextureUrl }
	if #Entries == 0 then
		InitialIcon = UserInputService.MouseIcon
	end
	table.insert(Entries, entry)
	UserInputService.MouseIcon = entry.Url
	return function()
		local index = table.find(Entries, entry)
		if index then
			table.remove(Entries, index)
		end
		-- one that went off under another leaves that one showing
		local top = Entries[#Entries]
		UserInputService.MouseIcon = if top then top.Url else InitialIcon
	end
end)
