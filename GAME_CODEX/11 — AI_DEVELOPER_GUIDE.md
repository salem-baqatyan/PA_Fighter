# AI Developer Guide

This is the working handoff for assistants modifying this repository. Source inspection takes precedence over this guide if code changes later. Read [CODEX_INDEX.md](00%20%E2%80%94%20CODEX_INDEX.md), [PROJECT_ARCHITECTURE.md](02%20%E2%80%94%20PROJECT_ARCHITECTURE.md), [SCRIPT_REFERENCE.md](04%20%E2%80%94%20SCRIPT_REFERENCE.md), and [KNOWN_ISSUES_AND_TECHNICAL_DEBT.md](09%20%E2%80%94%20KNOWN_ISSUES_AND_TECHNICAL_DEBT.md) first.

## What this project is

PA Fighter is a Godot 4.7-configured 2D two-player network arena prototype. Godot builds the lobby, reads controls, sends JSON over WebSocket and draws server snapshots. server/server.js is authoritative for room state, movement, dash, melee, health, respawn, tower defense/destruction and victory. Never infer flight from the lobby subtitle; no implementation was found.

## Authority map

| Behavior | Authoritative implementation |
|---|---|
| App entry/config/input | project.godot, main.tscn |
| Room flow and client transitions | scripts/core/Main.gd, scripts/ui/LobbyUI.gd |
| WebSocket client and JSON | scripts/networking/NetworkManager.gd |
| Movement input sampling and arena rendering | scripts/game/GameWorld.gd |
| Movement/combat/health/tower/match state | server/server.js |
| Client actor and HUD representation | scripts/players/PlayerAvatar.gd, scripts/towers/TowerNode.gd, scripts/ui/MobileHUD.gd |
| Camera | scripts/camera/CameraController.gd |
| Client character display values | scripts/core/CharacterCatalog.gd; server rules still win |
| Ability scaffold | scripts/combat/AbilityComponent.gd; no live caller/consumer found |

## Trace feature changes end to end

For control changes trace project.godot InputMap -> GameWorld._process() or MobileHUD/VirtualJoystick -> NetworkManager.send_message -> server handle()/updatePlayer() -> snapshot() -> GameWorld._apply_snapshot()/MobileHUD.apply_snapshot()/PlayerAvatar.apply_data().

For combat trace HUD and keyboard signals -> packet name -> server handler -> tryAttack/resolveAttack/damagePlayer/destroyTower -> snapshot fields -> visuals/HUD. For lobby trace LobbyUI signal -> Main handler -> NetworkManager -> server handle/joinRoom/startMatch -> lobby_state/match_started -> Main transition.

Treat message names and snapshot field spelling as compatibility interfaces: create_room, join_room, select_character, set_ready, start_match, input, attack, destroy_tower, rematch, return_lobby; mx/my/dash; player_id, team, character, x/y, facing_x/y, hp/max_hp, alive, dash_energy/dashing, destroy_charge, attack_timer, combo_index; towers, active_tower, phase, winner.

## Existing code conventions

GDScript uses tabs, type hints on many public boundaries, snake_case variables/functions, PascalCase class_name, signals for UI-to-coordinator communication, dictionaries for JSON snapshots, and _draw() for simple geometry. Server uses ES modules, camelCase local functions/fields, snake_case wire keys, plain object constants and in-memory Map state. Keep wire naming separate from internal naming. Avoid converting conventions wholesale.

There are no autoloads. Main is instantiated by the root scene. UI construction is largely programmatic. Scene wrappers are not currently the source of runtime instances, so inspect construction paths before modifying a .tscn. Keep script .uid sidecars paired when moving scripts.

## Safe change process

1. Inspect current relevant source and history; do not rely on this Codex alone.
2. Identify client, server, scene and data dependencies before editing. Do not assume client display values control gameplay.
3. Make a focused change and preserve unrelated behavior and message compatibility.
4. Check shared constants, bounds, class names, signals, node lookups and snapshot fields.
5. Validate with available target tools: Godot 4.7 import/parse/start when available; node --check server/server.js for server syntax; two connected clients for network behavior. Code inspection alone is not runtime testing.
6. Report exact changed paths and exact checks run, with pass/fail and any unverified behavior.
7. After a verified implementation change, update relevant Codex documents: status, authoritative paths, protocol/data, known issues, and roadmap. Do not label untested work verified.

## Areas requiring extra care

- Joystick class name mismatch: resolve against Godot before broader UI edits.
- Client/server character, arena and snapshot data are duplicated or tightly coupled.
- Scene wrappers are bypassed by .new() calls.
- Room state is memory-only; return/disconnect lifecycle should be exercised.
- Tower defense uses a shared per-player timer and ordered tower scan.
- No automated tests or Godot parser result exists in baseline.
- No physics bodies exist despite Jolt selection.
- Default URL binds clients to loopback; remote users must configure a reachable WebSocket endpoint.

## Rules for future assistants

Inspect relevant code before proposing edits. Do not invent mechanics, node trees, paths, or project goals. Avoid unsupported assumptions, duplicated logic, unnecessary rewrites and silent protocol changes. Preserve project behavior unless the request calls for a change. Never claim a test, import, launch or multiplayer behavior was verified unless it actually was. Clearly distinguish source evidence, inference and unknowns. When updating the Codex, include the audit date, source files inspected, validation performed, remaining limits, and exact files changed.

