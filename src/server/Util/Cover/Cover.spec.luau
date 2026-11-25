--!strict
-- Services
-- Packages
-- Modules
local CoverUtil = require("@game/ServerScriptService/Server/Util/Cover")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- a body is only ever asked where its middle is
local function newBody(position: Vector3): Model
	local body = Instance.new("Model")
	local rootPart = Instance.new("Part")
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.CFrame = CFrame.new(position)
	rootPart.Parent = body
	body.PrimaryPart = rootPart
	return body
end

local function newCover(cframe: CFrame, size: Vector3): BasePart
	local part = Instance.new("Part")
	part.Size = size
	part.CFrame = cframe
	return part
end
-- Class
return {
	-- a shield five studs in front of whoever carries it takes what comes at them from ahead, + nothing from anywhere
	-- else
	Shield = SpecUtil.newScenario(function()
		local owner, attacker = newBody(Vector3.zero), newBody(Vector3.new(0, 0, -20))
		local shield = newCover(CFrame.new(0, 1, -5), Vector3.new(12, 7, 0.2))
		assert(
			not CoverUtil.getIfBetween(Vector3.new(0, 0, -20), owner, attacker),
			`a cover that isn't up is in the way`
		)
		CoverUtil.add(shield, owner)
		assert(CoverUtil.getIfBetween(Vector3.new(0, 0, -20), owner, attacker), `a hit goes through the shield`)
		assert(CoverUtil.getIfBetween(Vector3.new(5.9, 0, -5.2), owner, attacker), `a hit from right before it gets by`)
		-- past its edge, over it, from behind + from between the shield + its owner
		assert(not CoverUtil.getIfBetween(Vector3.new(40, 0, -20), owner, attacker), `a hit from beside it is taken`)
		assert(not CoverUtil.getIfBetween(Vector3.new(0, 40, -20), owner, attacker), `a hit from above it is taken`)
		assert(not CoverUtil.getIfBetween(Vector3.new(0, 0, 20), owner, attacker), `a hit from behind is taken`)
		assert(
			not CoverUtil.getIfBetween(Vector3.new(0, 0, -3), owner, attacker),
			`a hit from between the two is taken`
		)
		-- along its face, a hair before it
		assert(
			not CoverUtil.getIfBetween(Vector3.new(-30, 0, -5.2), newBody(Vector3.new(30, 0, -5.2)), attacker),
			`a hit that runs along it is taken`
		)
		-- somebody else behind it is covered as well, whoever it belongs to
		assert(
			CoverUtil.getIfBetween(Vector3.new(0, 0, -20), newBody(Vector3.new(1, 0, 4)), attacker),
			`whoever stands behind the owner isn't covered`
		)
		-- what somebody carries is never in their own way
		assert(not CoverUtil.getIfBetween(Vector3.new(0, 0, 0), attacker, owner), `the shield is in its owner's way`)
		assert(
			CoverUtil.getIfBetween(Vector3.new(0, 0, 0), attacker, nil),
			`the shield isn't in the way of a hit of nobody's`
		)
		CoverUtil.remove(shield)
		assert(not CoverUtil.getIfBetween(Vector3.new(0, 0, -20), owner, attacker), `a cover that's gone is in the way`)
	end),

	-- the ice somebody is shut in takes every hit that's meant for them, + none of theirs
	Block = SpecUtil.newScenario(function()
		local owner, attacker = newBody(Vector3.new(100, 3, 0)), newBody(Vector3.new(100, 3, 30))
		local block = newCover(CFrame.new(100, 4, 0), Vector3.new(5, 7, 5))
		CoverUtil.add(block, owner)
		assert(CoverUtil.getIfBetween(Vector3.new(100, 3, 30), owner, attacker), `a hit gets into the block`)
		assert(CoverUtil.getIfBetween(Vector3.new(100, 60, 0), owner, attacker), `a hit gets into the block from above`)
		-- a way that starts inside doesn't go into it: out of the block + within it
		assert(not CoverUtil.getIfBetween(Vector3.new(100, 3, 0), attacker, owner), `the block is in its owner's way`)
		assert(
			not CoverUtil.getIfBetween(Vector3.new(100, 3, 0), attacker, nil),
			`a hit that starts inside goes into it`
		)
		assert(
			not CoverUtil.getIfBetween(Vector3.new(101, 3, 1), owner, attacker),
			`a hit from inside the block is taken`
		)
		-- right on its face is neither inside nor before it
		assert(
			not CoverUtil.getIfBetween(Vector3.new(100, 3, 2.5), owner, attacker),
			`a hit from its face goes into it`
		)
		CoverUtil.remove(block)
	end),

	-- a cover is asked in its own space, however it's turned + wherever it is
	Turned = SpecUtil.newScenario(function()
		local owner, attacker = newBody(Vector3.new(-50, 10, 50)), newBody(Vector3.new(-30, 10, 50))
		-- five studs towards the attacker, its thin side facing them
		local cframe = CFrame.lookAt(owner:GetPivot().Position, attacker:GetPivot().Position) * CFrame.new(0, 1, -5)
		local shield = newCover(cframe, Vector3.new(12, 7, 0.2))
		CoverUtil.add(shield, owner)
		assert(CoverUtil.getIfBetween(Vector3.new(-30, 10, 50), owner, attacker), `a hit goes through a turned shield`)
		assert(CoverUtil.getIfBetween(Vector3.new(-30, 10, 54), owner, attacker), `a hit at a slant goes through it`)
		assert(not CoverUtil.getIfBetween(Vector3.new(-50, 10, 70), owner, attacker), `a hit from its side is taken`)
		-- the same shield lying where it would be without the turn takes nothing of it
		CoverUtil.remove(shield)
		local flat = newCover(CFrame.new(owner:GetPivot().Position) * CFrame.new(0, 1, -5), Vector3.new(12, 7, 0.2))
		CoverUtil.add(flat, owner)
		assert(
			not CoverUtil.getIfBetween(Vector3.new(-30, 10, 50), owner, attacker),
			`a shield that faces away is in the way`
		)
		CoverUtil.remove(flat)
	end),
}
