--!strict
-- Services
-- Packages
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- fired as the effect is shown, the hud listens here so the effect doesn't have to know what a hud is
return Signal.new() :: Signal.Signal<>
