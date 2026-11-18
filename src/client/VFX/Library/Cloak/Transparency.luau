--!strict
-- Services
-- Packages
-- Modules
-- Types
-- both have a transparency, no class they share says so
export type Fadable = BasePart | Decal
-- how see-through something was before any effect got to it + how much of it each effect that's on takes away
type Entry = {
	Original: number,
	Amounts: { [{}]: number },
}
-- Constants
-- Variables
local Entries: { [Fadable]: Entry } = {}
-- References
-- Private Functions
local function apply(inst: Fadable, entry: Entry)
	local opacity = 1 - entry.Original
	local isHeld = false
	for _, amount in entry.Amounts do
		isHeld = true
		opacity *= 1 - amount
	end
	local fadable: any = inst
	fadable.Transparency = if isHeld then 1 - opacity else entry.Original
end
-- Class
local Module = {}

-- makes a part or a decal more see-through until what's handed back is called, 1 takes it away altogether. two
-- effects on the same avatar would otherwise put back what the other one left: they add up here + whatever it is
-- only goes back to how it was once the last of them let go
Module.hold = function(inst: Fadable, amount: number): () -> ()
	local fadable: any = inst
	local entry: Entry = Entries[inst] or { Original = fadable.Transparency, Amounts = {} }
	Entries[inst] = entry
	local key = {}
	entry.Amounts[key] = amount
	apply(inst, entry)
	return function()
		if entry.Amounts[key] == nil then
			return
		end
		entry.Amounts[key] = nil
		if next(entry.Amounts) == nil then
			Entries[inst] = nil
		end
		apply(inst, entry)
	end
end

-- the same hold for an effect that eases in + out: the second thing handed back changes how much of it the hold
-- takes away for as long as it's on
Module.holdEased = function(inst: Fadable, amount: number): (() -> (), (amount: number) -> ())
	local fadable: any = inst
	local entry: Entry = Entries[inst] or { Original = fadable.Transparency, Amounts = {} }
	Entries[inst] = entry
	local key = {}
	entry.Amounts[key] = amount
	apply(inst, entry)
	local function release()
		if entry.Amounts[key] == nil then
			return
		end
		entry.Amounts[key] = nil
		if next(entry.Amounts) == nil then
			Entries[inst] = nil
		end
		apply(inst, entry)
	end
	local function set(newAmount: number)
		if entry.Amounts[key] == nil then
			return
		end
		entry.Amounts[key] = newAmount
		apply(inst, entry)
	end
	return release, set
end

return Module
