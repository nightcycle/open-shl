--!strict
-- Services
-- Packages
-- Modules
local Scope = require("@game/ReplicatedStorage/Shared/VFX/Scope")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type VFX = VFXType.VFX
type Subject = VFXType.Subject
type Driver = VFXType.Driver
type Swap = VFXType.Swap
type Cleanup = VFXType.Cleanup
type ClientOptions = VFXType.ClientOptions
type Replication = VFXType.Replication
-- what a client effect does, looked up by its handle wherever client effects are run
export type Implementation = {
	Run: ((props: any, scope: any) -> ())?,
	Start: ((props: any, scope: any, swap: Swap?) -> Cleanup)?,
}
export type Options = {
	-- nil where client effects aren't run, like the server
	GetImplementation: ((vfx: VFX) -> Implementation?)?,
	-- whether server effects are run, they carry what they do themselves
	RunsServer: boolean,
	-- the last word on whether a client effect is shown at all
	GetIfShown: ((vfx: VFX, subject: Subject, options: ClientOptions?) -> boolean)?,
	-- told of every client effect that's shown, what the second one hands back is called as the state stops
	OnFire: ((vfx: VFX, props: unknown, subject: Subject, options: ClientOptions?) -> ())?,
	OnStart: ((vfx: VFX, props: unknown, subject: Subject, swap: Swap?, options: ClientOptions?) -> Cleanup?)?,
	FireClient: ((vfx: VFX, props: unknown, subject: Subject, replication: Replication) -> ())?,
	StartClient: ((vfx: VFX, props: unknown, subject: Subject, swap: Swap?, replication: Replication) -> Cleanup?)?,
}
-- Constants
-- Variables
-- References
-- Private Functions
local function new(options: Options, isQuiet: boolean): Driver
	local driver: Driver
	-- what a client effect runs inside of itself is part of it wherever it's shown, nobody is told of it twice
	local quietDriver: Driver?
	local function getInner(): Driver
		if isQuiet or (not options.OnFire and not options.OnStart) then
			return driver
		end
		local inner = quietDriver or new(options, true)
		quietDriver = inner
		return inner
	end

	local function getImplementation(vfx: VFX, subject: Subject, clientOptions: ClientOptions?): Implementation?
		local getClientImplementation = options.GetImplementation
		if not getClientImplementation then
			warn(`the "{vfx.Name}" effect is a client one, it isn't run here`)
			return nil
		end
		local implementation = getClientImplementation(vfx)
		if not implementation then
			warn(`nothing is registered for the "{vfx.Name}" effect`)
			return nil
		end
		if options.GetIfShown and not options.GetIfShown(vfx, subject, clientOptions) then
			return nil
		end
		return implementation
	end

	driver = {
		Fire = function(vfx: VFX, props: unknown, subject: Subject, clientOptions: ClientOptions?): unknown
			if vfx.Realm == "Client" then
				local implementation = getImplementation(vfx, subject, clientOptions)
				if not implementation or not implementation.Run then
					return nil
				end
				if options.OnFire and not isQuiet then
					options.OnFire(vfx, props, subject, clientOptions)
				end
				return Scope.fire(implementation.Run, props, subject, getInner())
			end
			assert(vfx.Realm == "Shared" or options.RunsServer, `the "{vfx.Name}" effect is a server one`)
			return Scope.fire((vfx :: any).Run, props, subject, driver)
		end,
		Start = function(
			vfx: VFX,
			props: unknown,
			subject: Subject,
			swap: Swap?,
			clientOptions: ClientOptions?
		): Cleanup?
			if vfx.Realm == "Client" then
				local implementation = getImplementation(vfx, subject, clientOptions)
				if not implementation or not implementation.Start then
					return nil
				end
				local onStop = if options.OnStart and not isQuiet
					then options.OnStart(vfx, props, subject, swap, clientOptions)
					else nil
				local cleanup = Scope.start(implementation.Start, props, subject, getInner(), swap)
				return function(stopSwap: Swap?)
					cleanup(stopSwap)
					if onStop then
						onStop(stopSwap)
					end
				end
			end
			assert(vfx.Realm == "Shared" or options.RunsServer, `the "{vfx.Name}" effect is a server one`)
			return Scope.start((vfx :: any).Start, props, subject, driver, swap)
		end,
		FireClient = options.FireClient,
		StartClient = options.StartClient,
	}
	return table.freeze(driver)
end
-- Class
local Module = {}

-- how the effects a scope is asked for are run in one place: a client, the server or a story
Module.new = function(options: Options): Driver
	return new(options, false)
end

return Module
