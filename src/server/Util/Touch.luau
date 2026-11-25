--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
-- Modules
-- Types
-- Constants
-- studs past its own corners a part still takes an avatar to be at it. a touch is whatever the client of an avatar
-- says it is, where the avatar stands is at least the server's own reading
local REACH = 10
-- Variables
-- References
-- Private Functions
-- Class
-- what every part of the map that's stepped on asks of a touch: whose it is + whether the server has them there
local Util = {}

Util.REACH = REACH

-- whose avatar the part belongs to: a hat or something held touches for whoever wears it
function Util.getToucher(hit: BasePart): (Player?, Model?)
	local model = hit:FindFirstAncestorOfClass("Model")
	while model do
		local player = Players:GetPlayerFromCharacter(model)
		if player then
			return player, model
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

function Util.getIfNear(character: Model, part: BasePart, reach: number): boolean
	local rootPart = character.PrimaryPart
	return rootPart ~= nil and (rootPart.Position - part.Position).Magnitude <= part.Size.Magnitude / 2 + reach
end

return Util
