--!strict
--!native
-- Services
local ContentProvider = game:GetService("ContentProvider")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local LoadingScreen = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/LoadingScreen")
-- Hooks
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
export type Properties = {}
-- a folder of asset/image: its files by name, its folders the same way. the checker has no type that takes both in
-- one table, so it's held to that when it's picked
type ImageGroup = { [string]: any }
-- Constants
local BATCH_SIZE = 8
-- how much of the bar belongs to the session, the images share the rest
local SESSION_SHARE = 0.2
-- an image that never loads or a server that never answers doesn't keep the player here
local TIME_CAP = 15
-- how long the full bar stays up
local HOLD_DURATION = 1
-- what's loaded ahead is the art of the game that's built, the groups of another game are never required
local IMAGE_GROUPS: { ImageGroup } = GameDefinition.pick({
	shl1 = function(): { ImageGroup }
		error(`shl1 has no images yet`)
	end,
	shl2 = function(): { ImageGroup }
		return require("@self/SHL2")
	end,
	shl3 = function(): { ImageGroup }
		error(`shl3 has no images yet`)
	end,
})
assert(Type.array(Type.map(Type.string, Type.union(Type.string, Type.table)))(IMAGE_GROUPS))
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function insertImages(out: { string }, group: ImageGroup)
	for _, value in group do
		if type(value) == "string" then
			table.insert(out, value)
		elseif type(value) == "table" then
			insertImages(out, value)
		end
	end
end

local function listImages(): { string }
	local out: { string } = {}
	for _, group in IMAGE_GROUPS do
		insertImages(out, group)
	end
	table.sort(out)
	table.freeze(out)
	return out
end
-- Class
return function(): React.ReactNode
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local isSessionLoaded = useSignalState(SessionService.Loaded, function(): boolean
		return SessionService:GetIsLoaded()
	end)
	local images = React.useMemo(listImages, {})
	local loadedCount, setLoadedCount = React.useState(0)
	local isTimedOut, setIsTimedOut = React.useState(false)
	React.useEffect(function()
		local isDead = false
		task.spawn(function()
			for i = 1, #images, BATCH_SIZE do
				local last = math.min(i + BATCH_SIZE - 1, #images)
				local batch = table.move(images, i, last, 1, {})
				local success, msg = pcall(function()
					ContentProvider:PreloadAsync(batch)
				end)
				if isDead then
					return
				end
				if not success then
					warn(`preload err: {msg}`)
				end
				setLoadedCount(last)
			end
		end)
		task.delay(TIME_CAP, function()
			if not isDead then
				setIsTimedOut(true)
			end
		end)
		return function()
			isDead = true
		end
	end, {})

	local isComplete = isTimedOut or (isSessionLoaded and loadedCount >= #images)
	local progress = 1
	if not isComplete then
		progress = (1 - SESSION_SHARE) * loadedCount / math.max(#images, 1)
		if isSessionLoaded then
			progress += SESSION_SHARE
		end
	end
	React.useEffect(function()
		if not isComplete then
			return function() end
		end
		local isDead = false
		task.delay(HOLD_DURATION, function()
			if not isDead and ShellService.IsInitialized then
				ShellService:FinishBootPhase("Loading")
			end
		end)
		return function()
			isDead = true
		end
	end, { isComplete })

	return e(
		LoadingScreen,
		{
			Size = UDim2.fromScale(1, 1),
			Progress = progress,
		} :: LoadingScreen.Properties
	)
end
