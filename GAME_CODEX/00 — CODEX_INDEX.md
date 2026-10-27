# PA Fighter Game Codex

Audit date: 2026-10-27  
Documentation version: 1.0  
Evidence basis: repository files at HEAD c6759cf (branch alaa-branch); working tree was clean before this Codex was created.

## Project identity

The configured Godot title is PA Fighter. The repository describes a two-player WebSocket arena prototype. A host creates a room, a second player joins, both choose Sword Fighter or Boxer and ready, and play consists of top-down movement, dash, directional melee, respawning, and destroying the opposing team's three towers. Match simulation and authority reside in the separate Node.js server. The lobby subtitle says “Two-player flying arena prototype,” but inspected movement and gameplay code contains no flight mechanic; flight is unverified and is not documented as implemented.

## Current status

This is an implementation-complete prototype across the statically inspected lobby, online match, movement, melee, respawn, tower, victory, and client display paths. None of the Godot behavior or live multiplayer has been runtime-verified in this audit. The Node server passed a JavaScript syntax check. The GDScript joystick class identifier discrepancy is a possible Godot parse blocker requiring validation in the target engine.

## Technical stack

- Godot project format config_version 5, configured feature version 4.7, GL Compatibility renderer.
- GDScript client using WebSocketPeer and dynamically constructed controls and drawing.
- Node.js ES module server using ws; server/package-lock.json pins ws 8.22.0.
- No Godot addons, other external client libraries, persistence, or external service integrations found.

## Codex documents

1. [GAME_OVERVIEW.md](01%20%E2%80%94%20GAME_OVERVIEW.md)
2. [PROJECT_ARCHITECTURE.md](02%20%E2%80%94%20PROJECT_ARCHITECTURE.md)
3. [SCENES_AND_NODE_HIERARCHY.md](03%20%E2%80%94%20SCENES_AND_NODE_HIERARCHY.md)
4. [SCRIPT_REFERENCE.md](04%20%E2%80%94%20SCRIPT_REFERENCE.md)
5. [GAMEPLAY_SYSTEMS.md](05%20%E2%80%94%20GAMEPLAY_SYSTEMS.md)
6. [INPUT_AND_USER_INTERFACE.md](06%20%E2%80%94%20INPUT_AND_USER_INTERFACE.md)
7. [ART_ASSETS_AND_AUDIO.md](07%20%E2%80%94%20ART_ASSETS_AND_AUDIO.md)
8. [CONFIGURATION_AND_DEPENDENCIES.md](08%20%E2%80%94%20CONFIGURATION_AND_DEPENDENCIES.md)
9. [KNOWN_ISSUES_AND_TECHNICAL_DEBT.md](09%20%E2%80%94%20KNOWN_ISSUES_AND_TECHNICAL_DEBT.md)
10. [DEVELOPMENT_ROADMAP.md](10%20%E2%80%94%20DEVELOPMENT_ROADMAP.md)
11. [AI_DEVELOPER_GUIDE.md](11%20%E2%80%94%20AI_DEVELOPER_GUIDE.md)

## Recommended reading order

Start here, then read GAME_OVERVIEW, PROJECT_ARCHITECTURE, SCENES_AND_NODE_HIERARCHY, and SCRIPT_REFERENCE. Read GAMEPLAY_SYSTEMS and INPUT_AND_USER_INTERFACE before changing gameplay. Read CONFIGURATION_AND_DEPENDENCIES and ART_ASSETS_AND_AUDIO for platform or presentation work. Check KNOWN_ISSUES_AND_TECHNICAL_DEBT and DEVELOPMENT_ROADMAP before planning changes. Keep AI_DEVELOPER_GUIDE open while making repository changes.

## Known gaps and verification limits

- No Godot executable was found on PATH; the configured .vscode path points to a D: drive installation unavailable here. Scene import, GDScript parse, launch, rendering, and input were not tested.
- No live WebSocket match was run. Server syntax only was checked.
- The static type name mismatch between MobileHUD.gd and VirtualJoystick.gd needs target-engine confirmation.
- Character/resource .tres files are name-only placeholders without evidence of runtime use.
- Godot autoload list is absent; no save, audio, ranged weapon, flight, AI, or physics-body gameplay was found in inspected files. This does not prove absence from ignored or external content.
- Ignored .godot and android directories are excluded by .gitignore and were not present in the tracked file inventory. No export presets were tracked.

## Audit summary

Inspected project.godot, all tracked scenes, scripts, resources, server source and package metadata, README/run instructions, icon/import metadata, tooling files, tracked inventory, working-tree status, and recent Git history. Cross-checked scene-to-script references, runtime construction, signals, input names, WebSocket message names, state/snapshot fields, and client/server gameplay constants. No tracked project content outside GAME_CODEX was modified. See individual documents for detailed evidence and limits.

