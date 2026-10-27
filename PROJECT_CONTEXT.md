# PA Fighter — Project Technical Reference

Inspected 2026-10-27. Statements below distinguish static evidence from runtime verification; see §4.15.

## 4.1 Project Overview

- Configured title: PA Fighter, from project.godot config/name. Lobby heading is PA-Fighter.
- Implemented in code: two-player online arena prototype with room creation/join, Sword Fighter/Boxer selection, ready/start, keyboard or joystick movement, dash, directional melee combos, death/respawn, tower destruction, victory and rematch. Godot handles controls/UI/rendering; server/server.js owns simulation. None of these systems were runtime-tested here.
- Evidence supports 2D top-down arena combat: Node2D/Camera2D, omnidirectional movement/facing, and procedurally drawn arena/player/towers. No sprite sheets, tilesets, fonts, or audio found. Lobby calls it a “flying arena prototype,” but no flying implementation was found.
- Engine configuration: feature 4.7, config version 5. .vscode/settings.json points to Godot 4.7.2 on D:, but that path was absent. Exact engine binary unavailable.
- Display: viewport 540×960; canvas_items stretch, expand aspect; handheld orientation 1. No explicit window mode. gl_compatibility renderer (including mobile), d3d12 Windows driver. Jolt Physics configured, but inspected client scenes have no physics bodies.
- Input Map: move_left A/Left, move_right D/Right, move_up W/Up, move_down S/Down, attack J/Space, dash Shift, destroy_tower E. Mobile HUD provides touch/mouse controls. No pause action.
- External dependency: npm ws; server/package-lock.json resolves version 8.22.0. No Godot addons/plugins found.
- No evidence of flight, ranged weapons/projectiles, TileMap levels, audio, save/load, progression, or Godot-side combat authority.

## 4.2 Project Directory and File Structure

Important res:// paths:

```text
res://
├── project.godot                     # entry scene, engine/display/input/render settings
├── main.tscn                         # configured entry; scripts/core/Main.gd
├── icon.svg, icon.svg.import         # project icon/import metadata
├── scenes/
│   ├── main/main.tscn                # alternate Main wrapper, not entry
│   ├── lobby/lobby_ui.tscn           # LobbyUI wrapper, apparently bypassed
│   ├── game/game_world.tscn          # GameWorld wrapper, apparently bypassed
│   ├── players/player_avatar.tscn    # PlayerAvatar wrapper, apparently bypassed
│   ├── towers/tower.tscn             # TowerNode wrapper, apparently bypassed
│   └── ui/mobile_hud.tscn            # HUD/joystick wrapper, apparently bypassed
├── scripts/
│   ├── core/{Main,GameState,CharacterCatalog}.gd
│   ├── networking/NetworkManager.gd
│   ├── game/GameWorld.gd
│   ├── players/PlayerAvatar.gd
│   ├── towers/TowerNode.gd
│   ├── combat/AbilityComponent.gd
│   ├── camera/CameraController.gd
│   └── ui/{LobbyUI,MobileHUD,VirtualJoystick}.gd
├── resources/
│   ├── characters/{sword_fighter,boxer}.tres
│   └── towers/default_tower_rules.tres
└── server/
    ├── server.js                     # authoritative match and WebSocket protocol
    ├── package.json, package-lock.json
    ├── README.md, run_code.txt
    └── node_modules/ws/              # present installed dependency
```

The .tres files contain only resource_name and appear unused. Script .uid sidecars exist; keep alongside scripts when moving/renaming. .godot/ and android/ are ignored; no .godot cache appeared in the listing. .editorconfig, .gitattributes, .gitignore and .vscode/settings.json are tooling/settings. server/node_modules is excluded above for brevity but affects local server execution; package lock can recreate it. No game art/audio/font/TileMap/addon assets found.

## 4.3 Main Entry Point and Execution Flow

1. project.godot starts res://main.tscn; Main root attaches scripts/core/Main.gd.
2. Main._ready() adds NetworkManager, connects connected/disconnected/message_received/status_changed, calls _show_lobby().
3. _show_lobby() constructs LobbyUI.new() once, wires room/character/ready/start signals, adds and displays it; it does not instance scenes/lobby/lobby_ui.tscn.
4. LobbyUI._ready() builds controls dynamically. Main records pending_action/selected_character and calls NetworkManager.connect_to_server().
5. NetworkManager._process() polls WebSocketPeer. On open it emits connected; Main sends create_room or join_room. JSON dictionaries emit message_received.
6. server.js responds with joined/lobby_state, etc. Main updates lobby. match_started calls _start_game().
7. _start_game() hides lobby, creates GameWorld.new(), calls initialize(network, local_id), connects leave_lobby_requested. GameWorld creates camera/HUD and listens for snapshots.
8. GameWorld._process() sends input every 0.05 sec (20 Hz); attack/tower actions immediately. Server ticks at 30 Hz, snapshots at 15 Hz. GameWorld._apply_snapshot() creates/updates player/tower drawings; MobileHUD.apply_snapshot() updates bars, tower text, victory UI.

No Autoloads. GameState is a class of constants. Rematch/return use network messages; Main handles return_lobby. There is no explicit level restart or clear Main disconnection/cleanup path. The configured root is top-level main.tscn, not scenes/main/main.tscn.

## 4.4 Scene and Node Architecture

Scene files are thin wrappers, but runtime flow mostly constructs objects using .new() rather than instancing the scenes.

| Scene | Hierarchy/script | Use/dependencies |
|---|---|---|
| res://main.tscn | Main: Node → scripts/core/Main.gd | Configured entry; adds network/lobby/world directly. |
| res://scenes/main/main.tscn | Main: Node → same script | Not selected as entry; apparently unused duplicate. |
| res://scenes/lobby/lobby_ui.tscn | LobbyUI: Control → LobbyUI.gd | Apparently bypassed; Main uses LobbyUI.new(). |
| res://scenes/game/game_world.tscn | GameWorld: Node2D → GameWorld.gd | Apparently bypassed; Main uses GameWorld.new(). |
| res://scenes/players/player_avatar.tscn | PlayerAvatar: Node2D → PlayerAvatar.gd | GameWorld uses PlayerAvatar.new(). |
| res://scenes/towers/tower.tscn | Tower: Node2D → TowerNode.gd | GameWorld uses TowerNode.new(). |
| res://scenes/ui/mobile_hud.tscn | MobileHUD: CanvasLayer → MobileHUD.gd; child VirtualJoystick: Control → VirtualJoystick.gd | GameWorld uses MobileHUD.new(), so child is absent. |

Approximate runtime tree: Main → NetworkManager, LobbyUI, GameWorld → CameraController, MobileHUD, PlayerAvatar*, TowerNode*. Camera targets the local avatar after a snapshot. GameWorld wires HUD signals with lambdas. Joystick direction_changed → MobileHUD._on_joystick_direction_changed → GameWorld.local_input. HUD looks up child name VirtualJoystick, and creates fallback if missing; runtime bypasses the scene child. Potential compile/type issue: MobileHUD types/casts as VirtualJoystick, but VirtualJoystick.gd declares class_name VirtualJoystickControl. Godot unavailable to confirm.

Preserve node names used in lookups and signal names. Scene wrapper edits may not affect runtime while .new() remains.

## 4.5 Script Architecture and Relationships

| Script | Responsibility/interfaces |
|---|---|
| scripts/core/Main.gd | Top-level coordinator; network/lobby/game_world/local_id/pending_action/selected_character; room flow and messages; starts GameWorld and handles leave_lobby_requested. |
| scripts/networking/NetworkManager.gd | WebSocket client, DEFAULT_URL ws://127.0.0.1:8090; emits connected, disconnected(reason), message_received(message), status_changed(status); connect_to_server/send_message/is_connected_to_server/close; polls and parses JSON. |
| scripts/core/GameState.gd | Phase enum and RED/BLUE/SWORD/BOXER constants. Phase is not used as an active client state machine. |
| scripts/core/CharacterCatalog.gd | Client names/stats/colors and get_config(); stats overlap server CHARACTERS. |
| scripts/game/GameWorld.gd | Drawn arena, input/network requests, snapshot reconciliation; creates PlayerAvatar/TowerNode. ARENA_RECT should align with server ARENA. |
| scripts/players/PlayerAvatar.gd | Snapshot-driven interpolation and drawing of body, health, attack effects; creates AbilityComponent. No movement/damage authority. |
| scripts/camera/CameraController.gd | Camera follow/look-ahead/bounds; exports arena_rect, look_ahead, smoothing; target set to local avatar. |
| scripts/towers/TowerNode.gd | Snapshot-driven tower visual; server owns actual rules. |
| scripts/combat/AbilityComponent.gd | enabled_slots defaults 0; can_activate/request_activate emits ability_requested. No caller/consumer found. |
| scripts/ui/LobbyUI.gd | Dynamically builds lobby; emits create_room/join_room/character_changed/ready_changed/start_requested; displays status/roster. |
| scripts/ui/MobileHUD.gd | Creates HP/dash/tower UI, buttons and victory panel; consumes snapshots; likely joystick type discrepancy. |
| scripts/ui/VirtualJoystick.gd | Touch/mouse control; radius/knob_radius; emits direction_changed; class_name VirtualJoystickControl. |

server/server.js is authoritative: room maps, protocol, 30 Hz simulation, attacks/damage, towers, death/respawn, snapshots. Client CharacterCatalog duplicates character values. Arena/tower values are also distributed across server and client. No direct circular script dependency identified; client/server field and constant coupling is significant.

## 4.6 Player Controller and Character Systems

No client CharacterBody2D, gravity, jumping, or collision movement. Server updatePlayer() reads normalized input, sets facing, accelerates/decelerates toward desired velocity, drains/regenerates dash energy, clamps to arena, advances position. GameWorld samples input; PlayerAvatar interpolates snapshot coordinates.

Character values occur in scripts/core/CharacterCatalog.gd and server/server.js CHARACTERS. Sword Fighter: 120 HP, speed 330, acceleration 1450, deceleration 1750, dash 700, energy 100, drain 48/s, regen 30/s, range 128, width 74, damage [22,24,34], cooldown .42s, active .20s, combo timeout .85s. Boxer: 135 HP, speed 360, acceleration 1650, deceleration 1900, dash 650, energy 100, drain 42/s, regen 36/s, range 82, width 58, damage [14,15,24], cooldown .24s, active .14s, timeout .70s. Server controls gameplay; client values serve presentation too.

Facing updates from movement above magnitude .08. Dash is held while input is down and energy remains; not a separate impulse. Server attack checks opponent distance ≤ range+24 and facing dot ≥ .25. Server owns HP/death and respawn delay 1.8s. No functioning client state machine; Phase enum unused. No separate aim, animation player, sprite flip, or camera shake. Camera uses look-ahead (180,130), smoothing 5, arena bounds.

## 4.7 Weapons and Combat Systems

No ranged weapon, projectile, ammo, reload, weapon switch, or pickup found. Melee flow:
1. GameWorld keyboard attack or MobileHUD attack_pressed sends attack.
2. Server handle() calls tryAttack(), checking phase/alive/cooldown and setting combo/cooldown/timer.
3. Server tick calls resolveAttack() from updatePlayer(); checks timer/opponent/range/facing and calls damagePlayer() at most once per swing.
4. Snapshots carry HP and attack visuals; PlayerAvatar draws health/attack, MobileHUD updates team health bars.

Kill may grant destroyCharge. HUD shows DESTROY TOWER; request invokes server tower decrement/victory. No audio or particle effects found. Preserve snapshot names attack_timer, combo_index, facing_x/y, HP and team.

## 4.8 Maps, World, Physics, and Collisions

One arena is drawn in GameWorld._draw(): ARENA_RECT Rect2(-2300,-1100,4600,2200). Server ARENA repeats extents and clamps players with 35-unit margin. No TileMap, TileSet, platform, collision shape/layer/mask, physics body, or level script found. Towers are Node2D drawings; proximity damage is server distance against electric_radius. Jolt is configured but no client collision system found.

New arena elements require reviewing GameWorld drawing/bounds, server ARENA/spawns/tower placement, CameraController and snapshot data. Client-only collision shapes do not constrain authoritative server movement.

## 4.9 User Interface and Gameplay Flow

- Lobby: LobbyUI._ready() creates server URL, room code, character selector, create/join, ready/start, status, slots and message. Server lobby_state updates slots and can_start. Room max length is 8; no broader client validation.
- HUD: MobileHUD builds team HP, dash energy, tower text, joystick, attack/dash buttons, conditional destroy, victory/rematch/return. Snapshots drive values. No ammo/score/pause interface.
- Victory: phase victory opens panel; rematch sends rematch; return sends return_lobby and emits local leave_lobby_requested.
- mobile_hud.tscn contains a joystick child, but MobileHUD.new() bypasses it; script creates a fallback. Type mismatch requires Godot validation.

## 4.10 Data, Configuration, and Resources

- project.godot controls title, entry, feature, display, input, renderer/physics settings.
- server/server.js is authority for simulation and gameplay values. CharacterCatalog.gd duplicates character data for display. Keep them aligned.
- resources/characters/sword_fighter.tres, boxer.tres and resources/towers/default_tower_rules.tres contain only resource_name; no references found. Runtime values are hard-coded.
- package.json/lockfile define ws; server/README.md documents manual launch. Godot does not start server. Default URL is loopback.
- No save/load, database, persistence, external art/audio. icon.svg.import is icon metadata.
- No missing scene/script resource reference confirmed statically; Godot import/load validation outstanding.

## 4.11 Current Project Status

| System | Status | Evidence | Remaining work or uncertainty |
|---|---|---|---|
| Project config/start | Implemented but not runtime-verified | project.godot, main.tscn | Godot parse/start not checked. |
| Lobby/room flow | Implemented but not runtime-verified | Main, LobbyUI, NetworkManager, server handlers | No live session. |
| Server | Implemented; JS syntax-verified only | server.js; node --check passed | Behavior not exercised. |
| Movement/dash | Implemented but not runtime-verified | server updatePlayer(), GameWorld | No live match; duplicated stats. |
| Melee/health/respawn | Implemented but not runtime-verified | tryAttack/resolveAttack/damagePlayer | Not exercised. |
| Towers/victory | Implemented but not runtime-verified | server defense/destruction, HUD | Not exercised. |
| Snapshot visuals/camera | Implemented but not runtime-verified | GameWorld, PlayerAvatar, TowerNode, CameraController | No render check. |
| Mobile controls | Partially implemented; not runtime-verified | input map, joystick/HUD | Type name may prevent parsing. |
| Ability slots | Present but apparently disconnected | AbilityComponent only | No caller/behavior/UI. |
| Scene wrappers/resources | Present but apparently disconnected | .tscn/.tres vs .new() flow | Intent unknown. |
| Physics world | Not implemented in inspected gameplay | No bodies/shapes | Physics setting exists. |
| Persistence/audio/ranged combat | Not implemented in inspected files | No refs/assets | External scope unknown. |

## 4.12 Bugs, Risks, and Potential Problems

| Finding | Priority | Evidence, impact and confidence |
|---|---|---|
| HUD references undeclared VirtualJoystick | High, possible build blocker | MobileHUD type/cast differs from VirtualJoystickControl class_name in VirtualJoystick.gd; could prevent parsing. Static mismatch; no Godot confirmation. |
| Scene wrappers bypassed | Medium | Main/GameWorld use .new() despite wrappers; scene edits may not affect runtime. Confirmed call sites. |
| Duplicated balance/bounds | Medium | CharacterCatalog/server CHARACTERS and client/server arena extents can drift. Confirmed. |
| Connection lifecycle unclear | Medium | Main disconnect handler shows lobby but doesn't reset pending_action/local_id; no obvious close invocation. Stale state possible; runtime effect unknown. |
| Tower electric timer | Investigate | applyElectricDefense decrements a shared player timer during tower iteration, returns at first in-range tower; overlapping zones could be order dependent. Intent unknown. |
| Redraw/performance | Investigate | Avatar redraw each frame; no profiling. Small current entity count; requires measurement. |

No issues fixed. Server leave() appears protected from duplicate close/error cleanup by removing socket mapping first. No automated tests were run.

## 4.13 Safe Project Modification Guide

- Movement/dash: inspect GameWorld.gd, project.godot input map, server updatePlayer/CHARACTERS/ARENA. Server owns motion. Preserve input keys mx/my/dash and snapshot x/y/dash_energy/dashing.
- Facing/attacks: inspect GameWorld, PlayerAvatar, server tryAttack/resolveAttack/snapshot, CharacterCatalog and server stats. Keep facing and attack fields aligned.
- Health/towers: inspect server damagePlayer/destroyTower/applyElectricDefense/makeTowers/TOWER_RULES and client TowerNode/MobileHUD. Preserve red/blue, tower IDs, chunks, active, destroy_charge.
- UI/controls: inspect LobbyUI, MobileHUD, VirtualJoystick, GameWorld signal wiring, input map. Verify joystick class mismatch first. UI is built in scripts; scene wrappers may be bypassed.
- Map/camera/collision: inspect GameWorld bounds/drawing, server ARENA/spawns/towers, CameraController. Client-only shapes don't constrain server simulation.
- Transitions/network: inspect Main, NetworkManager signal/close lifecycle, GameWorld listener cleanup, server handlers/leave. Preserve create_room, join_room, match_started, return_lobby, input, attack, destroy_tower, rematch.
- Preserve res://main.tscn and configured path, script .uid sidecars, lookup node names, signal names, packet schema. Trace runtime loading before editing wrappers.
- Recommended future validation: target Godot 4.7 import/parser, then two clients against server. Exercise room/readiness/start, movement/dash, melee/death/respawn, tower/victory, rematch/return. Compare client/server values. Not run here.

## 4.14 Incomplete Features and Future Development

### Confirmed unfinished work
- AbilityComponent is scaffolding: enabled_slots=0, no caller/consumer/UI.
- Prototype .tres resources contain names only and are unreferenced; actual data is hard-coded.
- Scene wrappers exist but observed runtime uses .new().
- Lobby says “flying” but no flight code; wording mismatch, not proof of an agreed feature.

### Recommended technical improvements
- Resolve/verify joystick type identifier and parse in target Godot.
- Reduce drift between server authority and client display constants.
- Add protocol/runtime validation for transitions/combat when development resumes.
- Decide whether wrappers/resources should be authoritative and align loading accordingly.

### Potential future features (not confirmed requirements)
Ranged weapons, flight, audio, profiles, more maps and abilities are possibilities, not established requirements.

## 4.15 Inspection and Testing Results

- Enumerated project and inspected settings, game scripts/scenes/resources, server source, metadata and docs.
- Traced references, signals, inputs, WebSocket messages, snapshot fields and duplicated constants.
- node --check server/server.js with Node v24.22.0: passed.
- Configured Godot path absent; no Godot binary on PATH. Game was not launched. No Godot import, parser, editor or runtime test.
- No live WebSocket session or gameplay test. No system claimed runtime-verified.
- GDScript parsing, scene/resource loading, rendering, controls, multiplayer and simulation remain unverified. Joystick mismatch is a static suspicion, not observed engine error.

## 4.16 AI HANDOFF SUMMARY

PA Fighter is a Godot 4.7-configured 2D online arena prototype. Godot handles lobby/input and snapshot rendering; [server/server.js](server/server.js) owns movement, dash, melee, health, respawn, towers and match state over WebSockets. Inspect [project.godot](project.godot), [main.tscn](main.tscn), [Main.gd](scripts/core/Main.gd), [GameWorld.gd](scripts/game/GameWorld.gd), [NetworkManager.gd](scripts/networking/NetworkManager.gd), [PlayerAvatar.gd](scripts/players/PlayerAvatar.gd), and [MobileHUD.gd](scripts/ui/MobileHUD.gd) first. Preserve message/snapshot fields, signal names, node assumptions and duplicated client/server constants. Main concern: VirtualJoystick vs VirtualJoystickControl; wrappers and .tres files appear unused. Godot/runtime and live multiplayer remain unverified. For future modifications trace both client sender/renderer and server handler/state/snapshot, then validate with Godot and two clients.

