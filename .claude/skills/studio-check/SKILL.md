---
name: studio-check
description: Build a place of open-shl (Superhero Life 1, 2 or 3) and drive it in Roblox Studio through the Studio MCP and the game's own dev harness. Use when a change has to be seen running (boot lines, a menu, a fight, a jail, a prop), when you need a second body to fight, when you need to read a session or the shell's state, or before saying anything "works" that only an engine can show.
---

# Checking open-shl in Roblox Studio

One strict-Luau codebase boots three games. `GAME` (`shl1`, `shl2`, `shl3`) and `MODE` are build variables; `deploy.yml`
lists the six places: `shl2 root`, `shl2 roleplay`, `shl2 private-server`, `shl3 root`, `shl3 roleplay`, `shl1 root`.
You verify a change by building one of them OUTSIDE the repo, opening that file in a NEW Studio window, and driving it
through the Studio MCP (`mcp__Roblox_Studio__*`) plus the harness described below.

Everything here runs from the repo root in Git Bash unless it says PowerShell. `<W>` is a scratch directory of your own
outside the repo (your session's scratchpad); `<SK>` is this folder, `.claude/skills/studio-check`.

## Hard rules

- **Never touch a Studio window you did not open.** The owner works on this machine with Studio windows of their own
  (other projects, sometimes this repo's `project.rbxl` with their `rojo serve`). Never run code in them, never Play
  them, never close them. `list_roblox_studios` shows all of them: pick yours by the place file's name, and check it.
- **Never send OS-level input** (no SendKeys, no mouse_event, no window focus, no waking a sleeping display). The MCP's
  own `user_mouse_input` / `user_keyboard_input` inside YOUR window are fine.
- **Never save, never publish.** Not from Studio (`save_place` is off limits), not from a terminal
  (`scripts/cd/publish.lune.luau` only ever with `DRY_RUN=true`). Close your window by stopping its process: that
  saves nothing.
- **Never open a legacy place file in Studio**: `Superhero Life.rbxl`, `Superhero Life II*.rbxl`,
  `Superhero Life III.rbxl`, `SHL3 Big Map.rbxl` in the repo root hold backdoor scripts. They are read through lune
  only. `open.ps1` refuses them.
- **Never switch the repo's generated files** (`Generated/BUILD_CONFIG.luau`, `default.project.json`,
  `sourcemap.json`) to another game, mode or flag: the owner's `rojo serve` reads them. Build in a snapshot.
- Never read or print `.env`. Never run `asphalt` with a help or verbose flag (it prints its key).
- Always stop Play and close your window when you are done. Only one agent drives Studio at a time.

## 1. Build a place without disturbing the working tree

```sh
# <source> is a commit (HEAD, a hash) or WORK (the working tree, uncommitted edits included)
sh <SK>/scripts/build-place.sh HEAD <W>/snap <W>/places/shl3-root.rbxl shl3 root HARNESS_ENABLED=true
```

- A commit is built from `git archive`, so nothing uncommitted and nothing of another agent's half-written work is in
  it. `Packages/`, `DevPackages/` and the generated asset tables come from the repo as they lie (they are git-ignored
  and never regenerated here).
- Extra `NAME=value` pairs are build variables on top of the place's own: `HARNESS_ENABLED=true` (the harness, below),
  `TESTS_ENABLED=true` (the server runs its specs before it starts and prints `[test] N passed, M failed`),
  `MODE_SELECT_ENABLED=false`.
- The script uses `robocopy` + `cygpath` when they exist (Windows + Git Bash) and `cp -R` otherwise. It finds the repo
  from its own location; `REPO=<path>` overrides.
- One snapshot directory per agent. Afterwards `<W>/snap` holds that place's `snap.project.json` + `BUILD_CONFIG`.
- Before opening a built file, read it: `lune run scripts/ci/check-place.lune.luau <place>` must end in
  `nothing wrong` (it holds the place to having no script outside the code mounts, which is how a backdoor rides in).

## 2. Open it in a NEW Studio window, find it, picture it, close it

PowerShell (the scripts keep their state in the folder of the place unless `-State` says otherwise):

```powershell
powershell -File <SK>/scripts/open.ps1 -Place <W>\places\shl3-root.rbxl      # prints  new: <pid>
powershell -File <SK>/scripts/window.ps1 -Id <pid> -State <W>\places -Out <W>\captures\a.png
powershell -File <SK>/scripts/close.ps1 -Id <pid> -State <W>\places
```

- `open.ps1` records every Studio process that was there before (`before-pids.txt`), starts the file, and takes the
  new process whose **window title names the place** (Studio puts the path of an opened file in its title). It writes
  the id to `opened-pids.txt`. `close.ps1` and `window.ps1` refuse any id that is not in that file or whose title no
  longer names the place. Give every place you build a file name of its own (`<you>-shl3-root.rbxl`): the name is
  how the window is told apart. Between Play and Edit the title is plain `RobloxStudio` for a moment; `close.ps1`
  waits that out, a refusal after it is real.
- Then `mcp__Roblox_Studio__list_roblox_studios`: your window is the entry whose name is the place's file name. Pass
  its `id` as `studio_id` to every MCP call. If two entries carry the name, stop and work out which is yours.
- `screen_capture` shows the 3D view and the game's own GUI but **not the engine's UI** (top bar, stock player list,
  hotbar, chat, health bar). `window.ps1` pictures the whole window by `PrintWindow` (no input, no focus);
  `-Box x,y,w,h` cuts it to a region, `-Scale 1` keeps every pixel.
- Three things of the tooling that cost earlier runs time:
  1. A new window may come up with Studio's **device simulator** on (a setting of the owner's Studio): Play is
     then a touch play in a phone-sized view. Read it in Edit mode and stop it in YOUR window for a desktop play
     (the setters throw on the server of a play):
     ```lua
     local simulator = game:GetService("StudioDeviceSimulatorService")
     local device, orientation = simulator:GetDeviceAsync(), simulator:GetOrientationAsync() -- "default" = off
     simulator:StopSimulationAsync()
     -- to turn it on again in this window (the device first: an orientation can't be set while none is on):
     simulator:SetDeviceAsync("iphone_17_pro"); task.wait(0.3)
     simulator:SetOrientationAsync(Enum.ScreenOrientation.LandscapeRight)
     ```
     What these calls set is that window's alone: a window opened right after does not come up with it, with or
     without a play in between. What a NEW window comes up with is Studio's own saved setting, and a run that
     closes its windows by stopping their process has been seen to end with it off where it began with it on
     (2026-11-23, nine windows; which step did it is not known). So write down what your first window came up
     with and what your last one did, and tell the owner if they differ: it is one click in the device bar for
     them, and nothing an agent may click.
  2. `execute_luau` puts `Camera.CameraType` back to what it was when the call began. A call that spans the end of
     an intro leaves the camera `Scriptable`. Fix it from inside one call with a
     `task.delay(0.5, function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)` and make no call
     until it fired.
  3. **A sleeping display or a minimized window draws no frames**: `RenderStepped` stops, tweens stand still, the
     MCP's mouse and keyboard reach nothing, `screen_capture` times out. Do not wake it. The harness below clicks
     nothing and waits on no frame, which is what it was built for, but it has only been run with the display on
     so far (2026-11-23): say plainly what was driven but not SEEN, and whether `Mounted` of `shell.get` still
     followed the shell.
- `execute_luau` takes `datamodel_type`: `Edit`, `Server` or `Client` (the last two only while playing:
  `start_stop_play`, then `get_studio_state`). Code run that way gets **its own copy of every ModuleScript**:
  `require(SomeService)` there is an uninitialised twin, never the running service. That is what the harness is for.
- What a boot has to print, in every game: `[boot] server ok (<game>)` and `[boot] client ok (<game>)`
  (`get_console_output`). Not yours: `saves are kept in memory only: the place isn't published`, three
  `ContentId: rbxassetid://203785492 failed`, the lines of the owner's plugins (Atmos: `Requiring asset ..` + a
  callstack), `Request asset was not found` for LinkedSource scripts of the shl2 map.

## 3. The harness

A dev-only bridge into the game's OWN module cache. It exists only in a place built with `HARNESS_ENABLED=true`
(default off; the publish script forces it off and leaves its modules out). The game never requires it.

- **Server**: `ServerStorage.Harness`, a BindableFunction. Console line: `[harness] server ok (N commands, ...)`.
- **Client**: `Players.LocalPlayer.PlayerScripts.Harness`, a BindableFunction that client made (the server and other
  clients cannot see it). Console line: `[harness] client ok (N commands, ...)`.
- Neither is a remote: no client can reach the server's.
- Call: `bindable:Invoke(command: string, args: table?)` -> `{ IsOk: boolean, Value: any?, Error: string? }`, plain
  data only (an instance comes back as its path, a Color3 as hex, a Vector3 as `{X, Y, Z}`). It never throws: an
  unknown command, a missing or misspelt argument, a refusal of the game all come back as `Error`. A field that is
  nil is simply not there (an attribute nobody wrote, a quest nobody runs).
- There is also a Roblox Studio skill for it, `open-shl-harness` (`get_roblox_skill`): the short form of this
  section. Its source is `roblox-studio-skill.md` beside this file; update both when the commands change.
- **`list`** on either side answers every command of that side in this game with its doc and its arguments. A
  command whose service this game does not start is not there (no `team.*` in shl2, no `playermode.*` in shl3).

Server, through `execute_luau` with `datamodel_type = "Server"`:

```lua
local harness = game:GetService("ServerStorage").Harness
local function call(command, args)
	return game:GetService("HttpService"):JSONEncode(harness:Invoke(command, args))
end
return call("list")
```

Client, with `datamodel_type = "Client"`:

```lua
local harness = game:GetService("Players").LocalPlayer.PlayerScripts.Harness
return game:GetService("HttpService"):JSONEncode(harness:Invoke("shell.get"))
```

### Commands (ask `list` for the exact arguments; a player argument may be left out while one player is in)

Server:

| command | what it does |
| --- | --- |
| `game.get` | game, mode, BUILD_CONFIG, features, the services started (in order), players, puppets, server time |
| `session.get` | a player's session: active slot + identity, every slot, balances, entitlements, quest, the game's own save section; `IsWhole = true` for the whole save |
| `avatar.get` | an avatar's or a puppet's state: every character attribute, fighting + seconds left, humanoid, tools in hand / Backpack, team, in-menu, held, costume |
| `character.select`, `character.swap` | another slot / the other identity, through the handler the real remote lands in |
| `economy.grant` | currency through `EconomyService:Grant` |
| `combat.hit` | `From` hits `To` for `Amount` through the real `Attack` effect; answers landed, hostile, taken, health, dead, both fight timers |
| `status.cover`, `status.freeze`, `status.burn` | what a power sets off besides its hit, on any body: Force Field's shield ahead of one for a while, one body freezing another (`IsBlocked` for the ice around them), one setting another alight. Each through the real effect, so the rule of the game may turn it down |
| `puppet.spawn`, `puppet.list`, `puppet.set`, `puppet.remove` | stand-ins for a second player's avatar (below) |
| `remote.list`, `remote.invoke` | every remote + whether this game answers it; any client function answered as if a player invoked it |
| `prop.get`, `prop.give`, `prop.take` | where the game has props (shl3) |
| `team.get`, `team.set` | where the game has sides (shl3): through `TeamService:ChangeTeam`, balance may refuse, the avatar goes down |
| `jail.get`, `jail.release` | where the game has a jail (shl3): release carries the avatar onto a road and waits for the jail's own check |
| `playermode.get`, `playermode.set` | where RP / PVP is each player's pick (shl1) |
| `event.read`, `event.wait` | the server's event log (below) |

Client:

| command | what it does |
| --- | --- |
| `shell.get` | boot phase, open screen + panel, hud visible / has shown, what the app has mounted (read off its instances), the game's registry, stops and menu rows |
| `shell.press` | presses a HUD button by its menu id through `ShellService:PressMenuButton` |
| `shell.close` | closes the open panel or screen |
| `boot.play` | "get me into play" with no click: finishes every boot phase of this game, then the character select through the real `SelectCharacter` request; answers where it ended and the steps it took |
| `player.get` | the local player's attributes, its avatar's, the workspace's, and the client's copy of the session |
| `remote.fire`, `remote.invoke` | any client event / function through the client's real network service |
| `acrobatics.get`, `acrobatics.play`, `acrobatics.fix` | where the game has the flips (shl1): a move by its id through the service the panel's buttons call (an error says why it was turned down), and what Fix Character does |
| `environment.get`, `environment.grade`, `environment.override`, `environment.clear` | where the game has a day (shl3): what this screen shows of it, one of the six grades, a season / weather / time of this screen's own, and back to the server's |
| `event.read`, `event.wait` | the client's event log |

### Getting into play without a mouse

```lua
-- Client
local harness = game:GetService("Players").LocalPlayer.PlayerScripts.Harness
return game:GetService("HttpService"):JSONEncode(harness:Invoke("boot.play", { Timeout = 40 }))
```

It waits for the session, gives the loading screen a few seconds to finish by itself, leaves the mode screen for the
mode of this place (shl2, shl3), the rules (shl1) or the intro (shl2, shl3), then selects a slot where the boot ends on
the character select (shl1, shl3). `IsInMenu = false` in the answer means the server counts the avatar as out of its
menus: from then on it can be hit (in shl2 a menu shelters nobody, there it is false from the start). `Steps` says
what it did: `["the session is in", "finished ModeSelect", "finished Intro", "selected <slot id>"]` in shl3.

`shell.press` answers with the shell's state a beat later, `Mounted` included, so one call both presses and shows
what the app drew. It answers an error for a button this game's hud does not have. A press the shell itself turns
down leaves the state as it was: `Characters` while the avatar is in a fight or down, `Build` outside a residence.

### A fight between two bodies

```lua
-- Server. a puppet stands 8 studs in front of the player, dressed as their active slot
local harness = game:GetService("ServerStorage").Harness
local json = function(v) return game:GetService("HttpService"):JSONEncode(v) end
local puppet = harness:Invoke("puppet.spawn", { Attributes = { TeamId = "Villains" } }) -- TeamId only where the game has sides
local last = harness:Invoke("event.read").Value.Last
local a = harness:Invoke("combat.hit", { To = puppet.Value.Name, Amount = 25 })            -- the player hits the puppet
local b = harness:Invoke("combat.hit", { From = puppet.Value.Name, To = "<player name>", Amount = 25 }) -- and back
local events = harness:Invoke("event.read", { Since = last, Kind = "Attribute" })
return json({ a, b, events })
```

- `IsLanded = false` with `IsHostile = false` is the game's rule turning the hit down: same side, somebody in a menu
  (`avatar.get` says), a peaceful body (shl1), a held villain that made no trouble (shl3), a spawn shield, or a place
  where nobody fights (`game.get` -> `IsPVPEnabled`).
- Health and the fight timer are attributes: `event.read` / `event.wait` with `Kind = "Attribute"`,
  `Subject = <name>`, `Where = { Name = "Health" }` (or `FightingUntil`, in shl1 and shl3: shl2 times no fight).
  `Time` of an event and `FightingUntil` are on the same clock. A body is down when its `IsDead` attribute turns
  true; `Died` is the engine's humanoid saying so a moment later.
- The damage that lands is the game's: `Amount` scaled by its rule (x1.5 in shl3, x1 in shl1 and shl2), and a hit
  that lands shoves the body where the game has knockback. `combat.hit` refuses a hit FROM a body that is down.
- Some of what the game does to a body will surprise you; it is the game, not the harness: `team.set` takes the
  avatar down and the next one comes in 5 s later on the new side (a villain in a cell, cuffed, as its Secret
  identity); `playermode.set` takes an avatar that is out in the world down, the next one plays by the pick.
- A puppet carries the attributes an avatar starts with plus whatever `Attributes` / `puppet.set` writes (each held
  to that attribute's validator). **What a puppet cannot stand in for:** it has no Player, so no session, no remotes,
  no powers or tools, no client, nothing paid or saved (a bounty names the PLAYER who downed somebody: a puppet's
  kill pays nobody), no name tag, no team-service or jail-service bookkeeping, no regeneration, and nothing replicates
  to a second client because there is none.

### Events

Each side keeps the last 2048 things it saw, numbered from 1. `event.read { Since?, Kind?, Subject?, Where? }` answers
`Events`, `First` (older ones fell out), `Last` (ask from here next) and `Kinds`. `event.wait { Kind, Since?, Subject?,
Where?, Timeout? }` yields until one arrives (after `Since`, or from now), up to `Timeout` seconds (10 by default, 120
at most; keep it under what an MCP call may take).

- Server kinds: `Spawned`, `Dressed`, `Attribute`, `PlayerAttribute`, `Died`, `ActiveCharacterChanged`,
  `InMenuChanged`, `Remote` (every event a client fires: `Name`, `Value`).
- Client kinds: `BootPhase`, `Screen`, `Panel`, `CameraMode`, `Residence`, `HudVisible`, `Tutorial`, `SwapRequested`,
  `SessionLoaded`, `ActiveCharacterChanged`, `MenuRefused`, `Spawned`, `Attribute`, `PlayerAttribute`, `Died`.
- Not in the log, because no signal exists to listen to: what a client asks a RemoteFunction, what the server fires at
  clients, React component actions.

### Adding a command

Commands are data beside what they drive: `src/server/Service/Harness/Command/<Area>.luau` and
`src/client/Service/Harness/Command/<Area>.luau`, one module per area, each requiring the real service. A command is
`Harness.newCommand(name, doc, { arguments }, run)` (`src/shared/Harness`), `run` answers a `Result`. Register a new
area in the `AREAS` list of that side's `Service/Harness/init.luau`, gated by the same feature its service is gated by
in `Definition/Service.luau`. Services never require the harness. Go through a service's public method or the handler
its remote lands in; never write a service's state.

## 4. What still needs a human

Two real clients (replication, name tags, a visitor at a door, a bounty paid to a second player), any sound, the
engine's own UI beyond a picture of it, touch and gamepad, a display that is asleep, and how anything feels.

## 5. The checks every change runs

In a snapshot (never the repo's own generated files), for each of `shl2`, `shl3`, `shl1`:

```sh
sh <SK>/scripts/build-place.sh WORK <W>/snap <W>/places/<game>-root.rbxl <game> root
cd <W>/snap
rojo sourcemap snap.project.json --output sourcemap.json
luau-lsp analyze --sourcemap sourcemap.json \
  --definitions "@roblox=<globalTypes.d.luau>" \
  --settings .luau-analyze.json --ignore "Packages/**" --ignore "DevPackages/**" src       # 0 errors
selene src                      # 0 errors, 0 warnings
stylua --check src scripts      # clean (run `stylua` on the files you touched)
lune run scripts/ci/check-place.lune.luau <place>          # ends in: nothing wrong
lune run scripts/util/check-catalogue.lune.luau <place>    # ends in: passed
```

- The definitions file: the one `scripts/ci/analyze.sh` downloads and pins (it prints the path), or on the owner's
  machine `C:/Users/nightcycle/repos/typed-instance-components/.tools/globalTypes.d.luau`. The VS Code extension's
  own file does not load with the pinned luau-lsp.
- A step that is meant to leave a game alone proves it with manifests of the place before and after:
  `lune run scripts/util/place-manifest.lune.luau manifest <place> <out.tsv>`, then `... diff <before.tsv> <after.tsv>`:
  every row that differs is yours and intended.
- The harness's modules ride along in a default build the way stories and specs do (nothing requires them; the type
  check sees them, which keeps them honest against the services they drive). `HARNESS_ENABLED=false` leaves them out
  entirely, which is what every published place gets.
- Commit messages: short, lower-case, what is now true. Stage explicit paths. Never push, never switch branches.
