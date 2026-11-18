--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
-- Types
export type Validator = MapDefinition.Validator
export type Tag<I> = MapDefinition.Tag<I>
export type Attribute<V> = MapDefinition.Attribute<V>
-- Constants
-- Variables
-- References
-- Private Functions
local newTag = MapDefinition.newTag
local newAttribute = MapDefinition.newAttribute
-- Class
-- what a map marks for the server to run, next to the marks both sides read
local Module = {}

-- the bulb of a street light, it holds the light it shines with
Module.StreetLamp = newTag("StreetLamp", "BasePart") :: Tag<BasePart>
-- the window panes of a building along with the colors they light up in
Module.NightWindows = newTag("NightWindows", "Model") :: Tag<Model>
Module.Uniform = newTag("Uniform", "Model") :: Tag<Model>
Module.Hazard = newTag("Hazard", "BasePart") :: Tag<BasePart>
Module.Beacon = newTag("Beacon", "BasePart") :: Tag<BasePart>
Module.Gate = newTag("Gate", "Model") :: Tag<Model>
Module.Reactor = newTag("Reactor", "Model") :: Tag<Model>
-- the parts of the model each get a color off the palette that sits among them
Module.Colorizer = newTag("Colorizer", "Model") :: Tag<Model>
-- loose parts that players knock over, every so often they're back where they started
Module.Rebuilt = newTag("Rebuilt", "Model") :: Tag<Model>

-- where an avatar comes into the world
Module.Spawn = newTag("Spawn", "SpawnLocation") :: Tag<SpawnLocation>
Module.PlayArea = MapDefinition.PlayArea
Module.Water = MapDefinition.Water
Module.IntroCamera = MapDefinition.IntroCamera

Module.UniformId = newAttribute("UniformId", Type.string) :: Attribute<string>
Module.GateId = newAttribute("GateId", Type.string) :: Attribute<string>
-- seconds, a beacon without one blinks at the pace of the rest
Module.CycleLength = newAttribute("CycleLength", Type.optional(Type.numberPositive)) :: Attribute<number?>

Module.list = MapDefinition.list
Module.get = MapDefinition.get

return Module
