--!strict
-- Services
-- Packages
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- fired as the effect is shown, the screen listens here so the effect doesn't have to know what a screen is
return Signal.new() :: Signal.Signal<ClientVFXType.Notice>
