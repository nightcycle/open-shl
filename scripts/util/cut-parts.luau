--!strict
-- takes the parts a catalogue couldn't be converted without cutting apart on the heights each names. only studio can:
-- a wedge or a cylinder on its side that lies across a joint comes apart into shapes no part is, so each half is a
-- union. convert-catalogue puts this into the place it writes with --cut-jobs, as ServerStorage.CutParts:
--   1. open that place in studio
--   2. command bar: require(game.ServerStorage.CutParts)()
--   3. save the place + hand it back to convert-catalogue with --take-cuts
-- Services
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
-- Types
-- Constants
local JOBS_NAME = "Jobs"
local CUTS_NAME = "Cuts"
local HEIGHT_DELIMITER = ","
-- what's taken off a part on one side of a height, big enough to cover whatever a body wears
local BLOCK_SIZE = 64
-- Variables
-- References
-- Private Functions
local function newBlock(part: BasePart, height: number, isAbove: boolean): Part
	local block = Instance.new("Part")
	block.Anchored = true
	block.Size = Vector3.one * BLOCK_SIZE
	block.Position =
		Vector3.new(part.Position.X, height + (if isAbove then BLOCK_SIZE else -BLOCK_SIZE) / 2, part.Position.Z)
	block.Parent = ServerStorage
	return block
end

-- what's left of a part between two heights, either of which can be left out
local function cut(part: BasePart, high: number?, low: number?): PartOperation?
	local blocks: { Instance } = {}
	if high then
		table.insert(blocks, newBlock(part, high, true))
	end
	if low then
		table.insert(blocks, newBlock(part, low, false))
	end
	local isOk, piece = pcall(function(): PartOperation
		return part:SubtractAsync(blocks) :: PartOperation
	end)
	for _, block in blocks do
		block:Destroy()
	end
	return if isOk then piece else nil
end
-- Class
return function()
	local jobs = Workspace:FindFirstChild(JOBS_NAME)
	assert(jobs, `the place has no Workspace.{JOBS_NAME}, it wasn't written with --cut-jobs`)
	local old = Workspace:FindFirstChild(CUTS_NAME)
	if old then
		old:Destroy()
	end
	local cuts = Instance.new("Folder")
	cuts.Name = CUTS_NAME

	local pieceCount = 0
	for _, part in jobs:GetChildren() do
		assert(part:IsA("BasePart"), `{part.Name} is no part`)
		local id = part:GetAttribute("Id")
		local heights: { number } = {}
		for _, text in string.split(part:GetAttribute("Heights"), HEIGHT_DELIMITER) do
			local height = tonumber(text)
			assert(height, `{id} names a height that's no number`)
			table.insert(heights, height)
		end
		-- from the top down
		table.sort(heights, function(a: number, b: number): boolean
			return a > b
		end)
		-- a cylinder whose two widths differ is cut while it's round + made wide afterwards, a round one is all a part
		-- can be
		local stretch: number = part:GetAttribute("Stretch") or 1
		for order = 1, #heights + 1 do
			local piece = cut(part, heights[order - 1], heights[order])
			assert(piece, `nothing of {id} is left between {heights[order - 1]} + {heights[order]}`)
			piece.Name = `{id}-{order}`
			piece.Anchored = true
			-- a union keeps the colors of what it was made of unless it's told to wear its own
			piece.UsePartColor = true
			piece.Size *= Vector3.new(1, 1, stretch)
			piece:SetAttribute("Id", id)
			piece:SetAttribute("Order", order)
			piece:SetAttribute("Part", part:GetAttribute("Part"))
			piece.Parent = cuts
			pieceCount += 1
		end
	end
	cuts.Parent = Workspace
	print(`cut {#jobs:GetChildren()} part(s) into {pieceCount} piece(s): save the place + hand it to --take-cuts`)
end
