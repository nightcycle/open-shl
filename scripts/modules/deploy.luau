--!strict
-- the deploy config says what each place of each universe is built with. the pipeline that publishes them + a terminal
-- that wants the build of one of them both read it through here, so neither can take it differently
-- Services
local fs = require("@lune/fs")
local serde = require("@lune/serde")
-- Packages
-- Modules
-- Types
export type Env = { [string]: string }
export type PlaceConfig = {
	place_id: number,
	version_type: string?,
	env: { [string]: any }?,
}
export type UniverseConfig = {
	universe_id: number,
	api_key_env: string,
	env: { [string]: any }?,
	places: { [string]: PlaceConfig },
}
export type DeployConfig = {
	universes: { [string]: UniverseConfig },
}
-- Constants
local DEFAULT_CONFIG_PATH = "deploy.yml"
local VERSION_TYPES = { "published", "saved" }
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.DEFAULT_CONFIG_PATH = DEFAULT_CONFIG_PATH

Module.readConfig = function(path: string): DeployConfig
	assert(fs.isFile(path), `no deploy config at "{path}"`)
	local config = serde.decode("yaml", fs.readFile(path))
	assert(type(config.universes) == "table", `"{path}" has no universes`)
	for universeName, universe in config.universes do
		local at = `universe "{universeName}"`
		assert(type(universe.universe_id) == "number", `{at} needs a universe_id`)
		assert(type(universe.api_key_env) == "string", `{at} needs an api_key_env`)
		assert(type(universe.places) == "table", `{at} has no places`)
		for placeName, place in universe.places do
			at = `place "{placeName}" of universe "{universeName}"`
			assert(type(place.place_id) == "number", `{at} needs a place_id`)
			assert(
				place.version_type == nil or table.find(VERSION_TYPES, place.version_type) ~= nil,
				`{at} has a version_type that's neither "published" nor "saved"`
			)
		end
	end
	return config
end

-- what the build scripts of one place are run with. its own word comes last, so it has the say over its universe
Module.getBuildEnv = function(universe: UniverseConfig, place: PlaceConfig): Env
	local env: Env = {}
	-- an id that isn't filled in yet is left unset, which the build scripts know how to take
	if universe.universe_id > 0 then
		env.UNIVERSE_ID = tostring(universe.universe_id)
	end
	if place.place_id > 0 then
		env.PLACE_ID = tostring(place.place_id)
	end
	for otherName, other in universe.places do
		if other.place_id > 0 then
			local key = string.upper((string.gsub(otherName, "[^%w]", "_")))
			env[`{key}_PLACE_ID`] = tostring(other.place_id)
		end
	end
	for _, extra: { [string]: any } in { universe.env or {}, place.env or {} } do
		for key, value in extra do
			env[key] = tostring(value)
		end
	end
	return env
end

return Module
