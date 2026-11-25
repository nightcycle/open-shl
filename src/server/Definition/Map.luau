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
-- a side of a part, by the name the engine has for it
type Face = "Top" | "Bottom" | "Left" | "Right" | "Front" | "Back"
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
-- a building that's robbed: its vaults, its triggers + its doors are found inside of it
Module.Bank = newTag("Bank", "Model") :: Tag<Model>
-- a grid of beams that's lethal while it's lit
Module.LaserGate = newTag("LaserGate", "Model") :: Tag<Model>
-- where a body nobody plays comes out of the ground
Module.ZombieSpawn = newTag("ZombieSpawn", "BasePart") :: Tag<BasePart>
-- a part that takes whoever steps on it on for the job it's named after
Module.JobPad = newTag("JobPad", "BasePart") :: Tag<BasePart>
-- a pad that sets whoever steps on it down at the exit of the same id
Module.Telepad = newTag("Telepad", "BasePart") :: Tag<BasePart>
Module.TelepadExit = newTag("TelepadExit", "BasePart") :: Tag<BasePart>
-- a door that fades out of the way for a while at a click on one of its buttons
Module.ClickDoor = newTag("ClickDoor", "Model") :: Tag<Model>
-- a screen that flickers through its pictures at a click
Module.ImageCycle = newTag("ImageCycle", "BasePart") :: Tag<BasePart>
-- a seat that puts one of its pictures on the face of whoever sits down
Module.FaceSwap = newTag("FaceSwap", "Seat") :: Tag<Seat>

-- where an avatar comes into the world
Module.Spawn = newTag("Spawn", "SpawnLocation") :: Tag<SpawnLocation>
Module.PlayArea = MapDefinition.PlayArea
Module.Water = MapDefinition.Water
Module.IntroCamera = MapDefinition.IntroCamera
Module.NightWindows = MapDefinition.NightWindows

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
Module.JobId = newAttribute("JobId", Type.string) :: Attribute<string>
-- a pad + the exit it leads to share one
Module.TelepadId = newAttribute("TelepadId", Type.string) :: Attribute<string>
-- seconds a door takes to fade + seconds it stays out of the way, + how see-through it is meanwhile
Module.FadeDuration = newAttribute("FadeDuration", Type.numberPositive) :: Attribute<number>
Module.OpenDuration = newAttribute("OpenDuration", Type.numberPositive) :: Attribute<number>
Module.OpenTransparency = newAttribute("OpenTransparency", Type.numberConstrained(0, 1)) :: Attribute<number>
-- files under asset/image with commas between them, in the order they're shown
Module.ImageKeys = newAttribute("ImageKeys", Type.string) :: Attribute<string>
-- the side of the screen the picture is on
Module.ImageFace =
	newAttribute("ImageFace", Type.literal("Top", "Bottom", "Left", "Right", "Front", "Back")) :: Attribute<Face>
-- seconds a picture is up for + seconds the whole run takes
Module.ImageInterval = newAttribute("ImageInterval", Type.numberPositive) :: Attribute<number>
Module.ImageDuration = newAttribute("ImageDuration", Type.numberPositive) :: Attribute<number>

Module.list = MapDefinition.list
Module.observe = MapDefinition.observe
Module.get = MapDefinition.get

return Module
