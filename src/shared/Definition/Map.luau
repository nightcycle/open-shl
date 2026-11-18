--!strict
-- Services
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
export type Validator = (value: unknown) -> (boolean, string?)
-- what a map marks for the game to run. _Signature is never set, it only carries the class of what wears the tag
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
-- the cast at the call is what types a handle, the same way it's done for a remote
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
-- the marks of a map that code on both sides reads, + what every mark is made with. the ones only the server runs
-- are with the server. a map is found by its marks alone, so the code follows whichever map a place is built with
local Module = {}

Module.newTag = newTag
Module.newAttribute = newAttribute

-- a box an avatar may be sent into, a map covers itself with as many as it takes
Module.PlayArea = newTag("PlayArea", "BasePart") :: Tag<BasePart>
-- a surface that's run across by whoever is fast enough
Module.Water = newTag("Water", "BasePart") :: Tag<BasePart>
-- the stops of the flight a player is shown the map by as they come in
Module.IntroCamera = newTag("IntroCamera", "Model") :: Tag<Model>

-- only what's in the world counts, a tagged template that waits in storage isn't run. asked again whenever it
-- matters: under streaming a client only holds what's near it + what its map keeps around for good
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

-- whether something that's at hand is one of them, which takes no walk of the map
Module.getIfTagged = function<I>(inst: Instance, tag: Tag<I>): boolean
	return inst:HasTag(tag.Name) and inst:IsA(tag.ClassName) and inst:IsDescendantOf(Workspace)
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
