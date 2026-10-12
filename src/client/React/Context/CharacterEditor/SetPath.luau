--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
export type SetPathCallback = (path: string?) -> ()
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(nil :: SetPathCallback?)
