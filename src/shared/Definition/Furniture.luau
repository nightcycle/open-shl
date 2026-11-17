--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
export type FurnitureDefinition = BaseType.FurnitureDefinition
export type FurnitureCategory = BaseType.FurnitureCategory
-- Constants
-- all in studs, bar the cap + the rotation
local PLACEMENT = table.freeze({
	GRID_SIZE = 0.2,
	PAD_SIZE = Vector2.new(20, 20),
	-- how far a footprint may hang over the edge of its pad
	PAD_MARGIN = 0.6,
	-- how far above the middle of its pad the primary part of a model sits
	PAD_HEIGHT_OFFSET = 0.3,
	MAX_PLACED = 70,
	NUDGE_DISTANCE = 1,
	ROTATION_INC_DEG = 45,
})
local CORNER_SIGNS = table.freeze({ -1, 1 })
local CATEGORIES: { FurnitureCategory } = table.freeze({
	"Vehicles" :: FurnitureCategory,
	"Workshop",
	"Armory",
	"Research",
	"Training",
	"Artifacts",
	"Conference",
})
-- thumbnail ids are from the old place
local DEFINITIONS: { FurnitureDefinition } = {
	{
		Id = "sports-car",
		Name = "Sports Car",
		Category = "Vehicles",
		Price = 15_000,
		Currency = PseudoEnum.Currency.Credits,
		IsFunctional = true,
		LegacyThumbnailId = 891936774,
	},
	{
		Id = "rocket-car",
		Name = "Rocket Car",
		Category = "Vehicles",
		Price = 220,
		Currency = PseudoEnum.Currency.Gems,
		IsFunctional = true,
		LegacyThumbnailId = 891937621,
	},
	{
		Id = "workbench",
		Name = "Workbench",
		Category = "Workshop",
		Price = 5_000,
		Currency = PseudoEnum.Currency.Credits,
		IsFunctional = false,
		LegacyThumbnailId = 891941504,
	},
	{
		Id = "gun-rack",
		Name = "Gun Rack",
		Category = "Armory",
		Price = 7_500,
		Currency = PseudoEnum.Currency.Credits,
		IsFunctional = false,
		LegacyThumbnailId = 891948501,
	},
	{
		Id = "suit-display",
		Name = "Suit Display",
		Category = "Workshop",
		Price = 6_000,
		Currency = PseudoEnum.Currency.Credits,
		IsFunctional = true,
		LegacyThumbnailId = 891950957,
	},
	{
		Id = "micro-reactor",
		Name = "Micro Reactor",
		Category = "Research",
		Price = 90,
		Currency = PseudoEnum.Currency.Gems,
		IsFunctional = false,
		LegacyThumbnailId = 891952275,
	},
	{
		Id = "punching-bag",
		Name = "Punching Bag",
		Category = "Training",
		Price = 500,
		Currency = PseudoEnum.Currency.Credits,
		IsFunctional = false,
		LegacyThumbnailId = 891954626,
	},
	{
		Id = "round-artifact-pedestal",
		Name = "Round Artifact Pedestal",
		Category = "Artifacts",
		Price = 4_000,
		Currency = PseudoEnum.Currency.Credits,
		IsFunctional = true,
		LegacyThumbnailId = 891988823,
	},
	{
		Id = "square-artifact-pedestal",
		Name = "Square Artifact Pedestal",
		Category = "Artifacts",
		Price = 50,
		Currency = PseudoEnum.Currency.Gems,
		IsFunctional = true,
		LegacyThumbnailId = 892016338,
	},
	{
		Id = "rectangular-meeting-table",
		Name = "Rectangular Meeting Table",
		Category = "Conference",
		Price = 4_500,
		Currency = PseudoEnum.Currency.Credits,
		IsFunctional = false,
		LegacyThumbnailId = 892018636,
	},
	{
		Id = "round-meeting-table",
		Name = "Round Meeting Table",
		Category = "Conference",
		Price = 6_000,
		Currency = PseudoEnum.Currency.Credits,
		IsFunctional = false,
		LegacyThumbnailId = 892024450,
	},
	{
		Id = "holographic-projector",
		Name = "Holographic Projector",
		Category = "Conference",
		Price = 50,
		Currency = PseudoEnum.Currency.Gems,
		IsFunctional = false,
		LegacyThumbnailId = 892024841,
	},
}
TableUtil.deepFreeze(DEFINITIONS)
-- Variables
local TemplateCache: { [string]: Instance? } = {}
-- References
local DecorationLibrary = IndexUtil.waitForPath("game/ReplicatedStorage/lib/base/decorations")
-- Private Functions
local function getIfFinite(cframe: CFrame): boolean
	for _, component in { cframe:GetComponents() } do
		if not (math.abs(component) < math.huge) then
			return false
		end
	end
	return true
end

-- Class
local Module = {}

Module.PLACEMENT = PLACEMENT

Module.get = function(id: string): Result<FurnitureDefinition, string>
	for _, definition in DEFINITIONS do
		if definition.Id == id then
			return Result.ok(definition)
		end
	end
	return Result.err(`no furniture "{id}"`)
end

Module.getTemplate = function(id: string): Result<Instance, string>
	do
		local cachedValue = TemplateCache[id]
		if cachedValue then
			return Result.ok(cachedValue)
		end
	end
	do
		-- an id from outside the catalogue could be a path into a template
		local definitionRes = Module.get(id)
		if definitionRes.IsErr then
			return Result.err(`template "{id}" failed: {definitionRes.Value}`)
		end
	end
	local templateRes = IndexUtil.tryFirstLocalPath(DecorationLibrary, id)
	if templateRes.IsOk then
		TemplateCache[id] = templateRes.Value
	end
	return templateRes
end

Module.getExtents = function(id: string): Result<Vector3, string>
	local templateRes = Module.getTemplate(id)
	if templateRes.IsErr then
		return Result.err(`extents of "{id}" failed: {templateRes.Value}`)
	end
	local template = templateRes.Value
	if not template:IsA("Model") then
		return Result.err(`extents of "{id}" failed: expected a Model, received a {template.ClassName}`)
	end
	return Result.ok(template:GetExtentsSize())
end

-- the footprint has to sit on a single pad, pieces may overlap
Module.getIfInBounds = function(id: string, cframe: CFrame): Result<boolean, string>
	local extentsRes = Module.getExtents(id)
	if extentsRes.IsErr then
		return Result.err(`bounds of "{id}" failed: {extentsRes.Value}`)
	end
	local extents = extentsRes.Value
	-- the corners only read the X + Z of a CFrame, a NaN from a client could hide in the rest of it
	if not getIfFinite(cframe) then
		return Result.ok(false)
	end
	local limit = PLACEMENT.PAD_SIZE / 2 + Vector2.new(PLACEMENT.PAD_MARGIN, PLACEMENT.PAD_MARGIN)
	for _, xSign in CORNER_SIGNS do
		for _, zSign in CORNER_SIGNS do
			local corner = cframe * Vector3.new(xSign * extents.X / 2, 0, zSign * extents.Z / 2)
			if not (math.abs(corner.X) <= limit.X and math.abs(corner.Z) <= limit.Y) then
				return Result.ok(false)
			end
		end
	end
	return Result.ok(true)
end

Module.listCategories = function(): { FurnitureCategory }
	return CATEGORIES
end

Module.list = function(category: FurnitureCategory?): { FurnitureDefinition }
	local out = {}
	for _, definition in DEFINITIONS do
		if category ~= nil then
			if category ~= definition.Category then
				continue
			end
		end
		table.insert(out, definition)
	end
	table.freeze(out)
	return out
end

return Module
