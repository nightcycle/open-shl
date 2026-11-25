--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local Cover = require("@game/ServerScriptService/Server/VFX/Library/Cover")
local ForceShield = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/ForceShield")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ServerContext = AbilityType.ServerContext
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local config = ForceShield.Config
-- the shield is the server's part, so it's in the way on every machine + of every hit the server is asked to take:
-- a ray ends at it, a swing from its far side lands nothing. it stops its owner's own ray for as long as it lingers,
-- + a friend's like anybody's
return AbilityBuilder.newServer(ForceShield.Layout)
	:Run(ForceShield.Layout.Bindings.Hold, Cover, function(context: ServerContext): Cover.Properties
		return {
			Size = config.Size,
			Offset = config.Offset,
			Color = context.Color or config.Color,
			Material = Enum.Material.Neon,
			Transparency = config.Transparency,
			FadeDuration = config.FadeDuration,
			Delay = config.Delay,
			Linger = config.Linger,
		}
	end)
	:Build()
