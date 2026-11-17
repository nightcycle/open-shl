--!strict
-- Services
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
export type Validator = (value: unknown) -> (boolean, string?)
-- what a map marks for the server to run. _Signature is never set, it only carries the class of what wears the tag
export type Tag<I> = {
	Name: string,
	ClassName: string,
	_Signature: (I) -> (),
}
-- what a tagged instance says about itself. _Signature is never set, it only carries the type of the value
export type Attribute<V> = {
	Name: string,
	Validator: Validator,
	_Signature: (V) -> (),
}
-- Constants
-- Variables
local Names: { [string]: true } = {}
-- References
-- Private Functions
local function newTag(name: string, className: string): any
	assert(not Names[name], `duplicate tag "{name}"`)
	Names[name] = true
	return table.freeze({
		Name = name,
		ClassName = className,
	})
end

local function newAttribute(name: string, validator: Validator): any
	assert(not Names[name], `duplicate attribute "{name}"`)
	Names[name] = true
	return table.freeze({
		Name = name,
		Validator = validator,
	})
end
-- Class
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

Module.UniformId = newAttribute("UniformId", Type.string) :: Attribute<string>
Module.GateId = newAttribute("GateId", Type.string) :: Attribute<string>
-- seconds, a beacon without one blinks at the pace of the rest
Module.CycleLength = newAttribute("CycleLength", Type.optional(Type.numberPositive)) :: Attribute<number?>

-- only what's in the world counts, a tagged template that waits in storage isn't run
Module.list = function<I>(tag: Tag<I>): { I }
	local out: { I } = {}
	for _, inst in CollectionService:GetTagged(tag.Name) do
		if not inst:IsDescendantOf(Workspace) then
			continue
		end
		if not inst:IsA(tag.ClassName) then
			warn(`{inst:GetFullName()} is tagged "{tag.Name}" but isn't a {tag.ClassName}`)
			continue
		end
		table.insert(out, inst :: any)
	end
	return out
end

Module.get = function<V>(inst: Instance, attribute: Attribute<V>): Result<V, string>
	local value = inst:GetAttribute(attribute.Name)
	local success, msg = attribute.Validator(value)
	if not success then
		return Result.err(`bad "{attribute.Name}" on {inst:GetFullName()}: {msg}`)
	end
	return Result.ok(value :: any)
end

return Module
