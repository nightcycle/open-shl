--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
export type SetIsHeroFocusCallback = (isHeroFocus: boolean) -> ()
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(nil :: SetIsHeroFocusCallback?)
