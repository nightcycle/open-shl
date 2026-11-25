--!strict
-- Services
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
-- Packages
-- Modules
local EnvironmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Environment")
-- Types
type WeatherLook = EnvironmentDefinition.WeatherLook
export type Drawer = {
	-- puts the sky of a weather up + has the fog come in or lift. rushed, nothing is eased into
	Set: (look: WeatherLook, isRushed: boolean) -> (),
	Destroy: () -> (),
}
-- Constants
local CLIMATE = EnvironmentDefinition.CLIMATE
-- where the lighting of a place keeps the skies a weather may name
local SKIES_NAME = "Skyboxes"
local FOG_TWEEN_INFO = TweenInfo.new(CLIMATE.ChangeDuration, Enum.EasingStyle.Linear)
-- Variables
-- References
-- Private Functions
-- Class
return {
	new = function(): Drawer
		-- the one that's up, by the name it was asked for under
		local skyName: string? = nil
		local sky: Sky? = nil
		local fogTween: Tween? = nil
		-- a place that came without one is told so once, not at every change of the weather
		local isWarned: { [string]: true } = {}

		local function hang(name: string): Sky?
			if sky and sky.Parent == Lighting and skyName == name then
				return sky
			end
			local skies = Lighting:FindFirstChild(SKIES_NAME)
			local template = skies and skies:FindFirstChild(name)
			if not template or not template:IsA("Sky") then
				if not isWarned[name] then
					isWarned[name] = true
					warn(`the lighting has no sky "{name}", the one that's up stays`)
				end
				return Lighting:FindFirstChildOfClass("Sky")
			end
			local newSky = template:Clone()
			newSky.Parent = Lighting
			-- the lighting only shows one of them, which isn't the one that came last
			for _, other in Lighting:GetChildren() do
				if other:IsA("Sky") and other ~= newSky then
					other:Destroy()
				end
			end
			sky = newSky
			skyName = name
			return newSky
		end

		local function stopFog()
			if fogTween then
				fogTween:Cancel()
				fogTween:Destroy()
				fogTween = nil
			end
		end

		return table.freeze({
			Set = function(look: WeatherLook, isRushed: boolean)
				-- whether the sun shows is the weather's word, not the sky's: the same clouds have one in a rain +
				-- none on a day that's only overcast
				local current = hang(look.Sky)
				if current then
					current.CelestialBodiesShown = look.IsSunny
				end
				local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
				if sunRays then
					sunRays.Enabled = look.IsSunny
				end

				stopFog()
				local fogEnd = if look.IsFoggy then CLIMATE.FogEnd.Foggy else CLIMATE.FogEnd.Clear
				if isRushed then
					Lighting.FogEnd = fogEnd
				else
					local tween = TweenService:Create(Lighting, FOG_TWEEN_INFO, { FogEnd = fogEnd })
					fogTween = tween
					tween:Play()
				end
			end,
			Destroy = function()
				stopFog()
			end,
		})
	end,
}
