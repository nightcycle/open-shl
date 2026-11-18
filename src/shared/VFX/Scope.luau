--!strict
-- Services
-- Packages
-- Modules
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type VFX = VFXType.VFX
type Subject = VFXType.Subject
type Driver = VFXType.Driver
type Swap = VFXType.Swap
type Cleanup = VFXType.Cleanup
type Handle = VFXType.Handle
type ClientOptions = VFXType.ClientOptions
type Replication = VFXType.Replication
-- Constants
local DEFAULT_REPLICATION: Replication = table.freeze({})
-- Variables
-- References
-- Private Functions
-- checked where the effect is asked for, so a mistake shows up next to whoever made it
local function getIfValid(vfx: VFX, props: unknown): boolean
	local success, msg = vfx.Props(props)
	if not success then
		warn(`bad props for the "{vfx.Name}" effect: {msg}`)
	end
	return success
end
-- Class
local Module = {}

-- the scope an effect is run with + what stops every state it started through it. the scope is typed by whoever
-- hands it on: the same table is a shared, a client or a server one depending on the driver behind it
Module.new = function(subject: Subject, driver: Driver): (any, Cleanup)
	local handles: { [Handle]: true } = {}
	local function track(cleanup: Cleanup?): Handle
		local handle: Handle
		handle = table.freeze({
			Stop = function(swap: Swap?)
				if not handles[handle] then
					return
				end
				handles[handle] = nil
				if cleanup then
					cleanup(swap)
				end
			end,
		})
		handles[handle] = true
		return handle
	end

	local fireClient = driver.FireClient
	local startClient = driver.StartClient
	local scope = table.freeze({
		Character = subject.Character,
		Player = subject.Player,
		IsOwner = subject.IsOwner,
		fire = function(vfx: VFX, props: unknown, options: ClientOptions?): unknown
			if not getIfValid(vfx, props) then
				return nil
			end
			return driver.Fire(vfx, props, subject, options)
		end,
		start = function(vfx: VFX, props: unknown, swap: Swap?, options: ClientOptions?): Handle
			return track(if getIfValid(vfx, props) then driver.Start(vfx, props, subject, swap, options) else nil)
		end,
		fireClient = function(vfx: VFX, props: unknown, replication: Replication?)
			assert(fireClient, `only the server shows clients the "{vfx.Name}" effect`)
			if getIfValid(vfx, props) then
				fireClient(vfx, props, subject, replication or DEFAULT_REPLICATION)
			end
		end,
		startClient = function(vfx: VFX, props: unknown, swap: Swap?, replication: Replication?): Handle
			assert(startClient, `only the server shows clients the "{vfx.Name}" effect`)
			return track(
				if getIfValid(vfx, props)
					then startClient(vfx, props, subject, swap, replication or DEFAULT_REPLICATION)
					else nil
			)
		end,
	})
	return scope, function(swap: Swap?)
		for handle in handles do
			handle.Stop(swap)
		end
	end
end

-- runs what an event does. an event has no end, so a state it starts is its own to stop
Module.fire = function(
	run: (props: any, scope: any) -> unknown,
	props: unknown,
	subject: Subject,
	driver: Driver
): unknown
	local scope = Module.new(subject, driver)
	return run(props, scope)
end

-- runs what a state does. whatever it started through its scope is stopped along with it
Module.start = function(
	start: (props: any, scope: any, swap: Swap?) -> Cleanup,
	props: unknown,
	subject: Subject,
	driver: Driver,
	swap: Swap?
): Cleanup
	local scope, stopChildren = Module.new(subject, driver)
	local cleanup = start(props, scope, swap)
	return function(stopSwap: Swap?)
		cleanup(stopSwap)
		stopChildren(stopSwap)
	end
end

return Module
