--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type Properties = ClientVFXType.ScreenFilter
-- Constants
local COLOR_NAME = "ScreenFilterColor"
local BLUR_NAME = "ScreenFilterBlur"
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.ScreenFilter, function(props: Properties)
	local camera = Workspace.CurrentCamera
	if not camera then
		return function() end
	end
	-- under the camera they're this machine's alone + never saved with a place
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = COLOR_NAME
	colorCorrection.Brightness = props.Brightness
	colorCorrection.Contrast = props.Contrast
	colorCorrection.Saturation = props.Saturation
	colorCorrection.TintColor = props.TintColor or colorCorrection.TintColor
	colorCorrection.Parent = camera
	local blur = Instance.new("BlurEffect")
	blur.Name = BLUR_NAME
	blur.Size = props.Blur
	blur.Parent = camera
	return function()
		colorCorrection:Destroy()
		blur:Destroy()
	end
end)
