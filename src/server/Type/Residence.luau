--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local ResidenceType = require("@game/ReplicatedStorage/Shared/Type/Residence")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type PlayerSave = SaveType.PlayerSave
type State = ResidenceType.State

local Types = {}

-- one residence of a map, there to be handed to a player. what names it is the game's to say
export type Slot = {
	Id: string,
	-- whatever the map shows of who lives there, nil once nobody does
	SetOwner: (player: Player?) -> (),
}
Types.Slot = Type.strictInterface({
	Id = Type.string,
	SetOwner = Type.callback,
})

-- what the residence service lets the part of it that's one game's own ask of it
export type Rooms = {
	-- whose residence a player is inside of, their own included
	GetHost: (player: Player) -> Player?,
	-- asks again if a player is given a residence, for a save that changed its answer in the middle of a visit: one
	-- who's due a residence + has none is handed one, one who has one + isn't due it any more gives it up
	Rehouse: (player: Player) -> (),
}
Types.Rooms = Type.strictInterface({
	GetHost = Type.callback,
	Rehouse = Type.callback,
})

-- the part of the residences that's one game's own: where they are in its map, who gets one, what's behind a door +
-- what its players do in there. the residence service does what every game with residences shares: who lives where,
-- who's inside of whose + who's told of a change
export type Rule = {
	-- every residence of the map, in the order they're handed out. it's asked once, as the service starts
	GetSlots: () -> { Slot },
	-- if a player with this save is given a residence at all
	GetIfHoused: (save: PlayerSave) -> boolean,
	-- if the door of an owner with this save stays shut for everybody else
	GetIfLocked: (save: PlayerSave) -> boolean,
	-- what a client builds the residence from, the way this game has it. a state that's equal to the last one isn't
	-- sent again
	NewState: (residenceId: string, owner: Player, save: PlayerSave) -> State,
	-- runs as the service starts, for the requests only this game takes. what it hands back undoes it
	Start: (rooms: Rooms) -> (() -> ())?,
}
Types.Rule = Type.strictInterface({
	GetSlots = Type.callback,
	GetIfHoused = Type.callback,
	GetIfLocked = Type.callback,
	NewState = Type.callback,
	Start = Type.callback,
})

return Types
