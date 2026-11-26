# The Roblox Studio skill `open-shl-harness`

The Studio MCP keeps skills of its own (`list_roblox_skills`, `get_roblox_skill`), stored with the Studio account under
Skills -> Personal, not in a place and not in this repo. This file is the source of the one that points agents at the
harness, so it can be made again on another account (`create_skill`) or brought up to date (`edit_skill`) when the
commands change. Keep it short: the long form is `SKILL.md` beside this file.

- **skill_name**: `open-shl-harness`
- **skill_description**: Drives a running open-shl place (Superhero Life 1, 2 or 3 built with HARNESS_ENABLED=true)
  through the game's own dev harness: one BindableFunction per side that reaches the real services. Use when a
  play-test of an open-shl place needs a session or avatar read, a way into play without a click, a HUD button pressed
  by id, a second body to fight, or a log of what happened, instead of requiring ModuleScripts from execute_luau.

## skill_body

````markdown
# open-shl harness

open-shl is one Luau codebase that boots three games (`shl1`, `shl2`, `shl3`). Code run through `execute_luau` gets its OWN copy of every ModuleScript, so `require(SomeService)` there is an uninitialised twin. A place built with `HARNESS_ENABLED=true` has a bridge into the game's real module cache instead. A place built without it has none: check the console for `[harness] server ok` / `[harness] client ok` after `[boot] server ok (<game>)` / `[boot] client ok (<game>)`.

The long form (how to build a place outside the repo, open it in a NEW Studio window, picture and close only that window, the hard rules, the checks) is the repo skill: `.claude/skills/studio-check/SKILL.md` in the open-shl repository. Read it before driving Studio.

## Rules

- Only ever act on the Studio window that holds the place you built (pick it by the place file's name in `list_roblox_studios`). Never run code in, Play, save or close any other window.
- Never save or publish a place. Never open a legacy `Superhero Life*.rbxl` or `SHL3 Big Map.rbxl`.
- Play first (`start_stop_play`), then use `datamodel_type = "Server"` or `"Client"`.

## The two bindables

```lua
-- Server
local harness = game:GetService("ServerStorage").Harness
-- Client
local harness = game:GetService("Players").LocalPlayer.PlayerScripts.Harness

local answer = harness:Invoke(command, args) -- { IsOk: boolean, Value: any?, Error: string? }, plain data, never throws
return game:GetService("HttpService"):JSONEncode(answer)
```

`harness:Invoke("list")` answers every command of that side in this game with its doc and arguments. Ask it first: commands differ per game (no `team.*` outside shl3, no `playermode.*` outside shl1).

## Server commands

`game.get`, `session.get`, `avatar.get`, `character.select`, `character.swap`, `economy.grant`, `combat.hit`, `status.cover`, `status.freeze`, `status.burn`, `puppet.spawn`, `puppet.list`, `puppet.set`, `puppet.remove`, `remote.list`, `remote.invoke`, `event.read`, `event.wait`; shl3 adds `prop.get`, `prop.give`, `prop.take`, `team.get`, `team.set`, `jail.get`, `jail.release`, `npc.raise`, `npc.list`, `npc.clear`, `crime.get`, `crime.hit`, `crime.alert`; shl1 adds `playermode.get`, `playermode.set`. A `Player` / `Body` argument may be left out while one player is in.

## Client commands

`shell.get`, `shell.press { MenuId }`, `shell.close`, `boot.play`, `player.get`, `remote.fire`, `remote.invoke`, `event.read`, `event.wait`.
In shl1 also `acrobatics.get`, `acrobatics.play { MoveId }`, `acrobatics.fix`.
In shl3 also `environment.get`, `environment.grade { Grade }`, `environment.override { Override }`, `environment.clear`.

## Recipes

Into play with no mouse (Client): `harness:Invoke("boot.play", { Timeout = 40 })` walks every boot phase of the game and its character select through the real request; the answer says where it ended and which steps it took.

A fight between two bodies (Server):

```lua
local puppet = harness:Invoke("puppet.spawn", { Attributes = { TeamId = "Villains" } }) -- TeamId only in shl3
local last = harness:Invoke("event.read").Value.Last
local a = harness:Invoke("combat.hit", { To = puppet.Value.Name, Amount = 25 })
local b = harness:Invoke("combat.hit", { From = puppet.Value.Name, To = "<player name>", Amount = 25 })
local seen = harness:Invoke("event.read", { Since = last, Kind = "Attribute" }) -- Health, FightingUntil, IsDead
```

`IsLanded = false` with `IsHostile = false` is the game's own rule turning the hit down (same side, a menu, a peaceful body, a held villain, a place where nobody fights).

A puppet is a rig with a character's attributes. It has no Player: no session, remotes, powers, client, pay or save, and nothing replicates to a second client.

Press a HUD button and read what the app drew (Client): `harness:Invoke("shell.press", { MenuId = "Shop" })`, then `shell.close`.

## What it cannot do

Two real clients, sound, the engine's own UI, touch and gamepad. With the display asleep nothing is drawn: the harness clicks nothing and waits on no frame, but say what was driven and not seen.
````
