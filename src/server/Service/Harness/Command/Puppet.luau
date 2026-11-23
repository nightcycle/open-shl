--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Future = TypeUnionLib.Future
-- Modules
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local HumanoidDescriptionBuilder = require("@game/ReplicatedStorage/Shared/Builder/HumanoidDescription")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Character = CharacterType.Character
type Command = Harness.Command
type Context = HarnessTypes.Context
type Body = HarnessTypes.Body
-- Constants
local RIG_TIMEOUT = 20
local DRESS_TIMEOUT = 20
-- studs in front of whoever it's put by, face to face
local DEFAULT_OFFSET = Vector3.new(0, 0, -8)
local NEAR = Harness.newArgument(
	"Near",
	"string",
	Type.string,
	"the player it stands in front of + is dressed as a slot of, whoever is alone on the server when left out"
)
local OFFSET = Harness.newArgument(
	"Offset",
	"Vector3",
	Type.Vector3,
	"where it stands from the avatar of that player, in the avatar's own space. 8 studs in front when left out"
)
local CHARACTER_ID = Harness.newArgument(
	"CharacterId",
	"string",
	Type.string,
	"the slot of that player it's dressed as, the one they play when left out"
)
local IDENTITY_KEY = Harness.newArgument(
	"IdentityKey",
	"string",
	CharacterType.IdentityKey,
	"Main or Secret, the identity the player is out as when left out"
)
local ATTRIBUTES = Harness.newArgument(
	"Attributes",
	"table",
	Type.map(Type.string, Type.any),
	'attributes of a character by name, each held to its own validator: { TeamId = "Villains", IsPeaceful = false }'
)
local IS_ANCHORED = Harness.newArgument(
	"IsAnchored",
	"boolean",
	Type.boolean,
	"true for one that stays where it's put whatever shoves it"
)
local PUPPET = Harness.newArgument("Puppet", "string", Type.string, "the name of a puppet")
-- Variables
-- References
-- Private Functions
-- writes attributes of the game onto a puppet, the way the services write them onto an avatar. the first that isn't
-- one, or that doesn't take its value, is what comes back
local function setAttributes(rig: Model, attributes: { [string]: any }): string?
	for name, value in attributes do
		local attribute: AttributeDefinition.Attribute<any>? = nil
		for _, other in AttributeDefinition.list("Character") do
			if other.Name == name then
				attribute = other
			end
		end
		if not attribute then
			return `no attribute "{name}" on a character`
		end
		local isValid, problem = attribute.Validator(value)
		if not isValid then
			return `"{name}" doesn't take that: {problem}`
		end
		AttributeDefinition.set(rig, attribute, value)
	end
	return nil
end

local function describe(body: Body): { [string]: any }
	local attributes: { [string]: any } = {}
	for _, attribute in AttributeDefinition.list("Character") do
		attributes[attribute.Name] = AttributeDefinition.get(body.Character, attribute)
	end
	return {
		Name = body.Name,
		Position = body.Character:GetPivot().Position,
		Attributes = attributes,
	}
end
-- Class
local Module = {}

-- a puppet stands in for the avatar of a second player where the rules only read the avatar: it's a rig of the game's
-- own body, dressed by the code that dresses an avatar, with the attributes an avatar starts out with. everything the
-- combat rule asks of a body (side, menu, peace, jail, health, the fight it's in) is on it. it has no player: no
-- session, no remotes, no powers, no client, nothing that's paid or saved, + no service that keeps its attributes up
Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"puppet.spawn",
			"puts a stand-in for a second player's avatar by a player: dressed as one of their slots, with a character's attributes",
			{
				Harness.optional(NEAR),
				Harness.optional(OFFSET),
				Harness.optional(CHARACTER_ID),
				Harness.optional(IDENTITY_KEY),
				Harness.optional(ATTRIBUTES),
				Harness.optional(IS_ANCHORED),
			},
			function(args: { [string]: any }): Result<any, string>
				assert(SessionService.IsInitialized, `the session service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Near)
				if playerRes.IsErr then
					return playerRes
				end
				local player = playerRes.Value
				local avatar = player.Character
				local sessionOpt = SessionService:Get(player)
				if not avatar or sessionOpt.IsNone then
					return Result.err(`{player.Name} has no avatar or no session to make one by`)
				end
				local session = sessionOpt.Value
				local characterId: string = args.CharacterId or session.Save.ActiveCharacterId
				local character: Character? = nil
				for _, other in session.Save.Characters do
					if other.Id == characterId then
						character = other
					end
				end
				local identityKey: CharacterType.IdentityKey = args.IdentityKey or session.ActiveIdentityKey
				local identity = if character then character.Identities[identityKey] else nil
				if not identity then
					return Result.err(`{player.Name} has no "{identityKey}" of a slot "{characterId}"`)
				end

				local rigF = Future.timeout(
					RigUtil.createFromDescription(HumanoidDescriptionBuilder.new():build(), nil, nil, true),
					RIG_TIMEOUT
				)
				-- the checker only knows what comes out of the future for an instance
				local rig: Model? = if rigF.IsCanceled then nil else rigF.Value :: any
				if not rig then
					return Result.err(`the engine made no rig in {RIG_TIMEOUT} seconds`)
				end
				-- what the avatar service does to an avatar as it comes in
				AttributeDefinition.setDefaults(rig, "Character")
				AttributeDefinition.set(rig, AttributeDefinition.PersonaName, identity.Profile.Name)
				AttributeDefinition.set(rig, AttributeDefinition.IdentityKey, identityKey)
				local humanoid = rig:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					humanoid.BreakJointsOnDeath = false
				end
				local problem = if args.Attributes then setAttributes(rig, args.Attributes) else nil
				if problem then
					rig:Destroy()
					return Result.err(problem)
				end

				local offset: Vector3 = args.Offset or DEFAULT_OFFSET
				local pivot = avatar:GetPivot()
				local position = pivot:PointToWorldSpace(offset)
				rig:PivotTo(CFrame.lookAt(position, Vector3.new(pivot.X, position.Y, pivot.Z)))
				local rootPart = rig:FindFirstChild("HumanoidRootPart")
				if rootPart and rootPart:IsA("BasePart") then
					rootPart.Anchored = args.IsAnchored == true
				end
				rig.Parent = Workspace
				-- the server keeps it. a rig that's left to the engine goes to the nearest client, which runs its
				-- humanoid from then on: the server never hears that one died
				if rootPart and rootPart:IsA("BasePart") and not rootPart.Anchored then
					pcall(function()
						rootPart:SetNetworkOwner(nil)
					end)
				end
				local body = context.Bodies:Add(rig)

				local dressF = Future.timeout(
					AppearanceUtil.apply(rig, identity.Appearance, AppearanceUtil.getClothes(player)),
					DRESS_TIMEOUT
				)
				local dressErrors: { string } = {}
				if dressF.IsCanceled then
					table.insert(dressErrors, `it wasn't dressed in {DRESS_TIMEOUT} seconds`)
				elseif dressF.Value.IsErr then
					dressErrors = dressF.Value.Value
				end
				local description = describe(body)
				description.DressErrors = dressErrors
				return Result.ok(description)
			end
		),
		Harness.newCommand("puppet.list", "every puppet that stands in the world", {}, function(): Result<any, string>
			local out: { any } = {}
			for _, body in context.Bodies:ListPuppets() do
				table.insert(out, describe(body))
			end
			return Result.ok(out)
		end),
		Harness.newCommand(
			"puppet.set",
			"writes attributes of a character onto a puppet: no service keeps them up for it, so this is what does",
			{ PUPPET, ATTRIBUTES },
			function(args: { [string]: any }): Result<any, string>
				local bodyRes = context.Bodies:Get(args.Puppet)
				if bodyRes.IsErr then
					return bodyRes
				end
				local body = bodyRes.Value
				if body.Player then
					return Result.err(`"{body.Name}" is a player: what's on an avatar is its services' to write`)
				end
				local problem = setAttributes(body.Character, args.Attributes)
				if problem then
					return Result.err(problem)
				end
				return Result.ok(describe(body))
			end
		),
		Harness.newCommand(
			"puppet.remove",
			"takes a puppet out of the world, or all of them when none is named. answers how many went",
			{ Harness.optional(PUPPET) },
			function(args: { [string]: any }): Result<any, string>
				return Result.ok(context.Bodies:Remove(args.Puppet))
			end
		),
	}
end

return Module
