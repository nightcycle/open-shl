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
-- a part that hands whoever steps on it the prop it's named after
Module.PropPad = newTag("PropPad", "BasePart") :: Tag<BasePart>
-- where somebody who's held is put as they come in, a model that holds its SpawnPoint
Module.JailCell = newTag("JailCell", "Model") :: Tag<Model>
-- whoever is held + gets further from it than its Radius is free
Module.JailCenter = newTag("JailCenter", "BasePart") :: Tag<BasePart>
-- + so is one that sets a foot on any part filed under it
Module.Road = newTag("Road", "Folder") :: Tag<Folder>
-- a pane only a hero or whoever holds the key walks through
Module.HeroGate = newTag("HeroGate", "BasePart") :: Tag<BasePart>
-- whoever is held + touches it is fair game from then on
Module.Troublesome = newTag("Troublesome", "BasePart") :: Tag<BasePart>

-- where an avatar comes into the world
Module.Spawn = newTag("Spawn", "SpawnLocation") :: Tag<SpawnLocation>
Module.PlayArea = MapDefinition.PlayArea
Module.Water = MapDefinition.Water
Module.IntroCamera = MapDefinition.IntroCamera

Module.UniformId = newAttribute("UniformId", Type.string) :: Attribute<string>
Module.GateId = newAttribute("GateId", Type.string) :: Attribute<string>
-- seconds, a beacon without one blinks at the pace of the rest
Module.CycleLength = newAttribute("CycleLength", Type.optional(Type.numberPositive)) :: Attribute<number?>
-- the id of a prop or what its hotbar calls it
Module.PropId = newAttribute("PropId", Type.string) :: Attribute<string>
-- seconds a pad is out of stock for once it handed one out, it never is without
Module.RestockDuration = newAttribute("RestockDuration", Type.optional(Type.numberPositive)) :: Attribute<number?>
-- studs from the center of a jail to where it lets go
Module.Radius = newAttribute("Radius", Type.numberPositive) :: Attribute<number>

Module.list = MapDefinition.list
Module.get = MapDefinition.get

return Module
