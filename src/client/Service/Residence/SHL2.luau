--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Residence = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/Residence")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local ResidenceType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Residence/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type ResidenceState = ResidenceType.State
type Door = ResidenceType.Door
type Interior = ResidenceType.Interior
type Walk = ResidenceType.Walk
type Rule = ResidenceType.Rule
-- Constants
local MAP_PATH = "game/Workspace/Map"
local APARTMENTS_PATH = "buildings/Apartments"
local DOORS_PATH = `{APARTMENTS_PATH}/Lobby/Doors`
local DOOR_TRIGGER_NAME = "Part"
local DOOR_PLATE_NAME = "Address"
local ANCHORS_PATH = `{APARTMENTS_PATH}/Residences`
local ANCHOR_NAME = "Anchor"
local LOBBY_TRIGGER_PATH = `{APARTMENTS_PATH}/Trigz`
-- the value under a trigger that holds the part it leads to
local EXIT_NAME = "Exit"
local DOORSTEP_DISTANCE = 4
-- Variables
-- References
-- Private Functions
local function tryPart(root: Instance, path: string): Result<BasePart, string>
	local instRes = IndexUtil.tryFirstLocalPath(root, path)
	if instRes.IsErr then
		return instRes
	end
	local inst = instRes.Value
	if not inst:IsA("BasePart") then
		return Result.err(`expected a BasePart at "{path}", received a {inst.ClassName}`)
	end
	return Result.ok(inst)
end

-- the plate with the name of the owner hangs on the side of the door the lobby is on
local function getDoorstep(door: BasePart, plate: BasePart): CFrame
	local out = door.CFrame.LookVector
	if (plate.Position - door.Position):Dot(out) < 0 then
		out = -out
	end
	local position = door.Position + out * DOORSTEP_DISTANCE
	return CFrame.lookAt(position, position + out)
end

-- a client only has the parts of the map around its avatar, so a teleport is bound as its trigger gets here + where it
-- leads is looked at once it's stepped on: the other side may show up later than the trigger did
local function bindTeleport(
	walk: Walk,
	connections: { RBXScriptConnection },
	triggers: { [BasePart]: true },
	map: Instance,
	desc: Instance
)
	if desc.Name ~= EXIT_NAME or not desc:IsA("ObjectValue") then
		return
	end
	local trigger = desc.Parent
	-- a trigger that left + came back is still bound from the first time
	if not trigger or not trigger:IsA("BasePart") or triggers[trigger] then
		return
	end
	triggers[trigger] = true
	table.insert(
		connections,
		walk.Bind(trigger, function()
			local exit = desc.Value
			-- the way back sits next to the exit under the same name
			local behind = exit and exit.Parent and exit.Parent:FindFirstChild(trigger.Name)
			if not exit or not exit:IsA("BasePart") or not behind or not behind:IsA("BasePart") then
				return
			end
			local apartments = IndexUtil.findFirstLocalPath(map, APARTMENTS_PATH)
			if apartments and trigger:IsDescendantOf(apartments) and not walk.GetIfReady() then
				return
			end
			if not walk.Land(exit, behind) then
				return
			end
			if trigger == IndexUtil.findFirstLocalPath(map, LOBBY_TRIGGER_PATH) and ShellService.IsInitialized then
				ShellService:FireTutorialTrigger("LobbyEntered")
			end
		end)
	)
end

-- every door of the lobby leads to the residence of the same name, whoever lives there
local function bindDoors(
	walk: Walk,
	connections: { RBXScriptConnection },
	enter: (door: Door) -> (),
	doors: Instance,
	anchors: Instance
)
	for _, inst in doors:GetChildren() do
		local triggerRes = tryPart(inst, DOOR_TRIGGER_NAME)
		local plateRes = tryPart(inst, DOOR_PLATE_NAME)
		local anchorRes = tryPart(anchors, `{inst.Name}/{ANCHOR_NAME}`)
		if not BaseType.ResidenceId(inst.Name) or triggerRes.IsErr or plateRes.IsErr or anchorRes.IsErr then
			warn(`"{inst.Name}" isn't the door of a residence`)
			continue
		end
		local door: Door = {
			ResidenceId = inst.Name,
			Doorstep = getDoorstep(triggerRes.Value, plateRes.Value),
			Anchor = anchorRes.Value.CFrame,
			Parent = anchorRes.Value.Parent or anchors,
		}
		table.freeze(door)
		table.insert(
			connections,
			walk.Bind(triggerRes.Value, function()
				enter(door)
			end)
		)
	end
end
-- Class
local Rule: Rule = {
	Bind = function(walk: Walk, enter: (door: Door) -> ()): () -> ()
		assert(ShellService.IsInitialized, `the shell service isn't initialized`)
		local connections: { RBXScriptConnection } = {}
		-- the teleports of the map that are bound
		local triggers: { [BasePart]: true } = {}
		local isBound = true
		local function getIfUnbound(): boolean
			return not isBound
		end
		-- the map is still on its way in when the client starts + what's far from the avatar may never get here
		task.spawn(function()
			local mapF = Future.awaitUntil(IndexUtil.getFuturePath(MAP_PATH), getIfUnbound)
			if not mapF.IsDone or not isBound then
				return
			end
			local map = mapF.Value
			table.insert(
				connections,
				map.DescendantAdded:Connect(function(desc: Instance)
					bindTeleport(walk, connections, triggers, map, desc)
				end)
			)
			for _, desc in map:GetDescendants() do
				bindTeleport(walk, connections, triggers, map, desc)
			end
		end)
		-- the doors + what they lead to are persistent in the map: every client has all of them, wherever its avatar is.
		-- not every map has residences, so nothing waits on them
		task.spawn(function()
			-- a map that isn't streamed comes in piece by piece, its doors are only all there once the game is
			if not game:IsLoaded() then
				game.Loaded:Wait()
			end
			local doorsF = Future.awaitUntil(IndexUtil.getFuturePath(`{MAP_PATH}/{DOORS_PATH}`), getIfUnbound)
			local anchorsF = Future.awaitUntil(IndexUtil.getFuturePath(`{MAP_PATH}/{ANCHORS_PATH}`), getIfUnbound)
			if not doorsF.IsDone or not anchorsF.IsDone or not isBound then
				return
			end
			bindDoors(walk, connections, enter, doorsF.Value, anchorsF.Value)
		end)
		return function()
			isBound = false
			for _, v in connections do
				v:Disconnect()
			end
			table.clear(connections)
		end
	end,
	-- an owner locks their door, the lock is theirs to show
	GetIfShut = function(owner: Player): boolean
		return AttributeDefinition.get(owner, AttributeDefinition.IsApartmentLocked)
	end,
	-- the remote the state came by only lets one of this game through, what a residence is built from is all in it
	NewInterior = function(anchor: CFrame, state: ResidenceState, parent: Instance): Result<Interior, string>
		return Residence.new(anchor, state :: any, parent) :: any
	end,
	GetBounds = function(interior: Interior): (CFrame, Vector3)
		local residence = Residence.from(interior)
		assert(residence and residence.IsAlive, `there's no residence to stay in`)
		return residence.Frame:GetBoundingBox()
	end,
	Entered = function(interior: Interior, isOwn: boolean, walk: Walk): (() -> ())?
		local residence = Residence.from(interior)
		local connections: { RBXScriptConnection } = {}
		if residence and residence.IsAlive then
			for _, passage in residence.Passages do
				table.insert(
					connections,
					walk.Bind(passage.Trigger, function()
						if not walk.GetIfReady() or not walk.Land(passage.Exit, passage.Return) then
							return
						end
						if passage.IsToBase and isOwn and ShellService.IsInitialized then
							ShellService:FireTutorialTrigger("BaseEntered")
						end
					end)
				)
			end
			table.insert(
				connections,
				walk.Bind(residence.ShelfTrigger, function()
					if residence.IsAlive then
						residence:OpenShelf()
					end
				end)
			)
		end
		-- a visitor looks around, the base is only built on by whoever it belongs to
		if isOwn and ShellService.IsInitialized then
			ShellService:SetIsInResidence(true)
			ShellService:FireTutorialTrigger("ApartmentEntered")
		end
		return function()
			for _, v in connections do
				v:Disconnect()
			end
			table.clear(connections)
			if ShellService.IsInitialized then
				ShellService:SetIsInResidence(false)
			end
		end
	end,
}

return table.freeze(Rule)
