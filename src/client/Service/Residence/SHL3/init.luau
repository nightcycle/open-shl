--!strict
-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
local Room = require("@self/Room")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Types
local ResidenceType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Residence/Types")
local ShellTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type ResidenceState = ResidenceType.State
type Door = ResidenceType.Door
type Interior = ResidenceType.Interior
type Walk = ResidenceType.Walk
type Rule = ResidenceType.Rule
-- Constants
-- what the rooms of this client are put under
local FOLDER_NAME = "Apartments"
-- the pad of the lobby that leads up + the spot over it an avatar that comes back down is put on
local ENTRANCE_PAD_NAME = "Telepad"
local ENTRANCE_SPOT_NAME = "Teleport"
local SALE_PANEL_ID: ShellTypes.PanelId = "ApartmentSale"
-- the old place stood an avatar a quarter turn off the pad it had come by
local LANDING_TURN = CFrame.Angles(0, math.rad(90), 0)
-- Variables
-- References
-- Private Functions
-- on the spot over a pad, turned a quarter away from it. the old place had the avatar lean as far as the pad lay
-- below the spot, here it's kept upright
local function getLanding(spot: BasePart, pad: BasePart): CFrame
	local position = spot.Position
	local offset = (pad.Position - position) * Vector3.new(1, 0, 1)
	if offset.Magnitude < 1e-3 then
		return CFrame.new(position)
	end
	return CFrame.lookAt(position, position + offset) * LANDING_TURN
end

-- the anchors of the tower are persistent in the map: every client has all of them, wherever its avatar is
local function getAnchor(residenceId: string): BasePart?
	for _, anchor in MapDefinition.list(MapDefinition.ApartmentAnchor) do
		local idRes = MapDefinition.get(anchor, MapDefinition.ResidenceId)
		if idRes.IsOk and idRes.Value == residenceId then
			return anchor
		end
	end
	return nil
end

-- the one way in is the pad of the lobby: it takes whoever owns a flat up to theirs, + nobody else anywhere
local function bindEntrance(walk: Walk, enter: (door: Door) -> (), parent: Instance, entrance: Model): (() -> ())?
	local pad = entrance:FindFirstChild(ENTRANCE_PAD_NAME)
	local spot = entrance:FindFirstChild(ENTRANCE_SPOT_NAME)
	if not pad or not pad:IsA("BasePart") or not spot or not spot:IsA("BasePart") then
		warn(`{entrance:GetFullName()} isn't the way into a flat`)
		return nil
	end
	local doorstep = getLanding(spot, pad)
	local connection = walk.Bind(pad, function()
		-- the server says who lives where through an attribute on every player
		local residenceId = AttributeDefinition.get(Players.LocalPlayer, AttributeDefinition.ResidenceId)
		local anchor = if residenceId then getAnchor(residenceId) else nil
		if not residenceId or not anchor then
			return
		end
		local door: Door = {
			ResidenceId = residenceId,
			Doorstep = doorstep,
			Anchor = anchor.CFrame,
			Parent = parent,
		}
		enter(table.freeze(door))
	end)
	return function()
		connection:Disconnect()
	end
end

-- the server put a prompt on him. it comes + goes with him as the map around the avatar does, + may get here after
-- he did
local function bindSalesman(salesman: Model): (() -> ())?
	local connections: { RBXScriptConnection } = {}
	local function bindPrompt(desc: Instance)
		if not desc:IsA("ProximityPrompt") then
			return
		end
		table.insert(
			connections,
			desc.Triggered:Connect(function()
				if ShellService.IsInitialized then
					-- without the hud there's nothing to talk about: the shell says no + nothing opens
					ShellService:OpenPanel(SALE_PANEL_ID)
				end
			end)
		)
		-- the avatar walked off, as the dialog of the old place ended with the distance
		table.insert(
			connections,
			desc.PromptHidden:Connect(function()
				if ShellService.IsInitialized then
					ShellService:ClosePanel(SALE_PANEL_ID)
				end
			end)
		)
	end
	table.insert(connections, salesman.DescendantAdded:Connect(bindPrompt))
	for _, desc in salesman:GetDescendants() do
		bindPrompt(desc)
	end
	return function()
		for _, v in connections do
			v:Disconnect()
		end
		table.clear(connections)
	end
end
-- Class
local Rule: Rule = {
	Bind = function(walk: Walk, enter: (door: Door) -> ()): () -> ()
		assert(ShellService.IsInitialized, `the shell service isn't initialized`)
		-- a room only exists on the client of its owner, it's put where the server has nothing
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = Workspace
		local unbindEntrances = MapDefinition.observe(MapDefinition.ApartmentEntrance, function(entrance: Model)
			return bindEntrance(walk, enter, folder, entrance)
		end)
		local unbindSalesmen = MapDefinition.observe(MapDefinition.ApartmentSalesman, bindSalesman)
		return function()
			unbindEntrances()
			unbindSalesmen()
			folder:Destroy()
		end
	end,
	-- nobody visits: the lobby has no door to knock on, its pad only ever leads to the flat of whoever steps on it
	GetIfShut = function(_owner: Player): boolean
		return true
	end,
	-- the remote the state came by only lets one of this game through, what a room is built from is all in it
	NewInterior = function(anchor: CFrame, state: ResidenceState, parent: Instance): Result<Interior, string>
		return Room.new(anchor, state :: any, parent) :: any
	end,
	GetBounds = function(interior: Interior): (CFrame, Vector3)
		local room = Room.from(interior)
		assert(room and room.IsAlive, `there's no room to stay in`)
		return room:GetBounds()
	end,
	GetLanding = function(interior: Interior): CFrame
		assert(interior.IsAlive, `there's no room to land in`)
		return getLanding(interior.Entrance, interior.Exit)
	end,
	Entered = function(interior: Interior, _isOwn: boolean, _walk: Walk): (() -> ())?
		local room = Room.from(interior)
		if not room or not room.IsAlive then
			return nil
		end
		local liveRoom = room
		-- the pane of the tower the room is built behind is the window of whoever is inside: it's seen through from
		-- in here + stays as solid as it is to everybody else
		local pane = getAnchor(liveRoom.State.ResidenceId)
		if pane then
			pane.LocalTransparencyModifier = 1
		end
		-- a room of another tier has its floor elsewhere, the avatar is put on the spot of the new one
		local rebuiltConnection = liveRoom.Rebuilt:Connect(function()
			local avatar = Players.LocalPlayer.Character
			if avatar and liveRoom.IsAlive then
				avatar:PivotTo(getLanding(liveRoom.Entrance, liveRoom.Exit))
			end
		end)
		return function()
			rebuiltConnection:Disconnect()
			if pane then
				pane.LocalTransparencyModifier = 0
			end
		end
	end,
}

return table.freeze(Rule)
