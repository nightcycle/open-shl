--!strict
-- Services
local TextService = game:GetService("TextService")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Future = TypeUnionLib.Future
-- Modules
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

-- the filter is a web call that can fail + take a while
function Util.filter(text: string, userId: number): TypeUnionLib.ToDo<Result<string, string>>
	return Future.toDo(function(): Result<string, string>?
		local success, res = pcall(function(): string
			local filterResult = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)
			return filterResult:GetNonChatStringForBroadcastAsync()
		end)
		if not success then
			return Result.err(`filter threw: {res}`)
		end
		return Result.ok(res)
	end)
end

return Util
