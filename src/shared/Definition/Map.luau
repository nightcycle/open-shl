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
-- the window panes of a building along with the colors they light up in
Module.NightWindows = newTag("NightWindows", "Model") :: Tag<Model>
-- ground, water + trees that change with the season. a tree's leaves are parts of its own
Module.SeasonGround = newTag("SeasonGround", "BasePart") :: Tag<BasePart>
Module.SeasonWater = newTag("SeasonWater", "BasePart") :: Tag<BasePart>
Module.Foliage = newTag("Foliage", "Model") :: Tag<Model>
-- what a fountain runs with + where its water comes out
Module.Fountain = newTag("Fountain", "BasePart") :: Tag<BasePart>
Module.Spout = newTag("Spout", "BasePart") :: Tag<BasePart>
-- a beam that sweeps a vault, it's drawn where each client has it
Module.LaserBeam = newTag("LaserBeam", "Model") :: Tag<Model>
-- a half of the door of a vault, every client slides the ones it has
Module.VaultDoor = newTag("VaultDoor", "Model") :: Tag<Model>
-- what a disaster is fought at, the bar over it is found by it
Module.DisasterTarget = newTag("DisasterTarget", "Model") :: Tag<Model>
-- a flat of the apartment block, the door into the block + who sells them
Module.ApartmentAnchor = newTag("ApartmentAnchor", "BasePart") :: Tag<BasePart>
Module.ApartmentEntrance = newTag("ApartmentEntrance", "Model") :: Tag<Model>
Module.ApartmentSalesman = newTag("ApartmentSalesman", "Model") :: Tag<Model>
-- a part that turns for show, on every client by itself
Module.Spin = newTag("Spin", "BasePart") :: Tag<BasePart>

-- water that's ice in the winter
Module.Freezes = newAttribute("Freezes", Type.optional(Type.boolean)) :: Attribute<boolean?>
-- seconds a beam takes from one end of its sweep to the other
Module.SweepDuration = newAttribute("SweepDuration", Type.numberPositive) :: Attribute<number>
-- studs a half of a vault door moves up as it opens, the lower half goes down
Module.Slide = newAttribute("Slide", Type.number) :: Attribute<number>
Module.DisasterId = newAttribute("DisasterId", Type.string) :: Attribute<string>
-- which slot of the block a flat is
Module.ResidenceId = newAttribute("ResidenceId", Type.string) :: Attribute<string>
-- the part's own axis it turns about + the radians a second it turns by, signed
Module.SpinAxis = newAttribute("SpinAxis", Type.literal("X", "Y", "Z")) :: Attribute<"X" | "Y" | "Z">
Module.SpinRate = newAttribute("SpinRate", Type.number) :: Attribute<number>

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

-- what wears the tag in the world now + whatever comes to: under streaming most of a client's map comes + goes, a walk
-- that's done once misses it. what onAdded returns is run as its instance leaves the world or loses the tag, + for all
-- that's left as the returned function ends the watch. onAdded mustn't yield
Module.observe = function<I>(tag: Tag<I>, onAdded: (I) -> (() -> ())?): () -> ()
	-- what's in the world, + what each of them left to undo
	local isIn: { [Instance]: true } = {}
	local cleanUps: { [Instance]: () -> () } = {}
	local connections: { [Instance]: RBXScriptConnection } = {}

	local function leave(inst: Instance)
		local cleanUp = cleanUps[inst]
		isIn[inst] = nil
		cleanUps[inst] = nil
		if cleanUp then
			cleanUp()
		end
	end

	local function update(inst: Instance)
		if inst:IsDescendantOf(Workspace) == (isIn[inst] == true) then
			return
		end
		if isIn[inst] then
			leave(inst)
		else
			isIn[inst] = true
			local cleanUp = onAdded(inst :: any)
			if cleanUp then
				cleanUps[inst] = cleanUp
			end
		end
	end

	-- a template that waits in storage is tagged long before it's put in the world, which no signal of the tag tells
	local function watch(inst: Instance)
		if connections[inst] then
			return
		end
		if not inst:IsA(tag.ClassName) then
			warn(`{inst:GetFullName()} is tagged "{tag.Name}" but isn't a {tag.ClassName}`)
			return
		end
		connections[inst] = inst.AncestryChanged:Connect(function()
			update(inst)
		end)
		update(inst)
	end

	local function unwatch(inst: Instance)
		local connection = connections[inst]
		if not connection then
			return
		end
		connection:Disconnect()
		connections[inst] = nil
		leave(inst)
	end

	local addedConnection = CollectionService:GetInstanceAddedSignal(tag.Name):Connect(watch)
	local removedConnection = CollectionService:GetInstanceRemovedSignal(tag.Name):Connect(unwatch)
	for _, inst in CollectionService:GetTagged(tag.Name) do
		watch(inst)
	end

	return function()
		addedConnection:Disconnect()
		removedConnection:Disconnect()
		for inst in table.clone(connections) do
			unwatch(inst)
		end
	end
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
