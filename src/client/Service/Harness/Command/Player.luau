--!strict
-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
-- Constants
-- Variables
-- References
-- Private Functions
-- read through the definition, so one that was never written says its default
local function getAttributes(inst: Instance?, owner: AttributeDefinition.Owner): { [string]: any }?
	if not inst then
		return nil
	end
	local attributes: { [string]: any } = {}
	for _, attribute in AttributeDefinition.list(owner) do
		attributes[attribute.Name] = AttributeDefinition.get(inst, attribute)
	end
	return attributes
end
-- Class
local Module = {}

Module.list = function(): { Command }
	return {
		Harness.newCommand(
			"player.get",
			"what this client knows of its own player: the attributes the ui reads off the player, the avatar + the world, + its copy of the session",
			{},
			function(): Result<any, string>
				assert(SessionService.IsInitialized, `the session service isn't initialized`)
				local player = Players.LocalPlayer
				local characters: { any } = {}
				for _, character in SessionService:GetCharacters() do
					local names: { [string]: string } = {}
					for identityKey, identity in character.Identities :: { [string]: any } do
						names[identityKey] = identity.Profile.Name
					end
					table.insert(characters, {
						Id = character.Id,
						Names = names,
					})
				end
				return Result.ok({
					Name = player.Name,
					Team = if player.Team then player.Team.Name else nil,
					PlayerAttributes = getAttributes(player, "Player"),
					-- nil while there's no avatar
					AvatarAttributes = getAttributes(player.Character, "Character"),
					WorkspaceAttributes = getAttributes(Workspace, "Workspace"),
					Session = {
						IsLoaded = SessionService:GetIsLoaded(),
						ActiveCharacterId = SessionService:GetActiveCharacterId(),
						ActiveIdentityKey = SessionService:GetActiveIdentityKey(),
						Characters = characters, -- in slot order
					},
				})
			end
		),
	}
end

return Module
