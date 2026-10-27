# Project Architecture

## Repository map

| Path | Role |
|---|---|
| project.godot, main.tscn | Godot configuration and selected entry scene. |
| scripts/core | Root coordinator, shared constants, client character presentation data. |
| scripts/networking | Godot WebSocket client and JSON message signals. |
| scripts/game | Input sampling, arena drawing, snapshot reconciliation. |
| scripts/players, scripts/towers, scripts/camera | Snapshot-driven visuals and camera following. |
| scripts/ui | Lobby, HUD, and virtual joystick implemented in GDScript. |
| scripts/combat | AbilityComponent scaffold, attached to every PlayerAvatar. |
| scenes | Thin .tscn wrappers for root, lobby, game, avatar, tower, and HUD. |
| resources | Three prototype .tres resources that only set resource_name; no usage found. |
| server | Node.js authoritative simulation, protocol, setup docs and ws dependency. |
| icon.svg, icon.svg.import | Godot project icon and texture import metadata. |
| PROJECT_CONTEXT.md | Existing technical summary; useful corroboration, not runtime evidence. |
| .vscode, .editorconfig, .gitattributes, .gitignore | Editor and Git settings. |

Tracked server/node_modules/ws contents are checked in. .godot and /android are ignored. No addons, tests, CI workflow, export preset, or other asset directory was found in tracked files.

## Authority boundary

The Godot client sends intentions and renders snapshots. It does not calculate movement, hits, health, respawn, tower damage, or winner. server/server.js keeps room/player state in in-memory Maps, updates active rooms at 30 Hz, and broadcasts a full JSON snapshot at up to 15 Hz. Client input packets are sent every 0.05 s (nominally 20 Hz).

## Startup and runtime object graph

project.godot selects res://main.tscn. Its Main Node attaches scripts/core/Main.gd. Main._ready() adds NetworkManager, wires its four signals, then shows LobbyUI. Main constructs the lobby via LobbyUI.new(), not its .tscn. On match_started it hides lobby, constructs GameWorld.new(), calls initialize(network, local_id), then GameWorld constructs CameraController and MobileHUD. On snapshots it creates PlayerAvatar and TowerNode instances with .new(), updates them from dictionaries, and points the camera at the local avatar.

Runtime outline:

    project.godot -> main.tscn -> Main.gd
      -> NetworkManager <-> server/server.js
      -> LobbyUI
      -> GameWorld -> CameraController
                   -> MobileHUD -> VirtualJoystick (fallback instance)
                   -> PlayerAvatar* -> AbilityComponent
                   -> TowerNode*

A scene wrapper is not automatically the object used by this path. The current call sites bypass all wrappers except configured main.tscn.

## Message and state flow

Lobby events: LobbyUI signals create_room/join_room/character_changed/ready_changed/start_requested -> Main -> NetworkManager.send_message(). Server sends joined, lobby_state, match_started, error, return_lobby.

Match controls: GameWorld samples keyboard and joystick state, sends input {mx,my,dash} every 0.05 sec; attack/destroy_tower are immediate messages. HUD signals route attack, dash, destroy, rematch, return_lobby. NetworkManager parses JSON Dictionary packets and emits message_received to Main and, while active, GameWorld. GameWorld consumes snapshot; HUD and avatar/tower visuals consume relevant snapshot fields.

GameWorld disconnects its message_received connection in _exit_tree(). Main and NetworkManager remain as parent/root lifetime objects. Main does not call NetworkManager.close() on return-to-lobby or disconnect; connection reuse is expected by current structure.

## Scene composition, signals, and resources

Scene wrappers have the hierarchies documented in [SCENES_AND_NODE_HIERARCHY.md](03%20%E2%80%94%20SCENES_AND_NODE_HIERARCHY.md). Runtime controls are built programmatically. Resource .tres files are not loaded or preloaded by inspected scripts. GDScript classes use class_name for the global types NetworkManager, GameWorld, PlayerAvatar, TowerNode, AbilityComponent, CameraController, CharacterCatalog, GameState, LobbyUI, MobileHUD, and VirtualJoystickControl. There are no autoload/singleton registrations in project.godot; Main is an ordinary root node.

## Configuration and dependencies

Project uses Godot format version 5, configured feature 4.7 and GL Compatibility. Node server uses ES modules and ws. See [CONFIGURATION_AND_DEPENDENCIES.md](08%20%E2%80%94%20CONFIGURATION_AND_DEPENDENCIES.md). Default client endpoint is loopback-only, ws://127.0.0.1:8090; remote hosting needs a reachable endpoint supplied in the lobby.

## Architectural strengths and risks

- Authority for competitive state is server-side and clearly separated from rendering.
- Snapshot keys form an implicit client/server contract without schema validation or protocol versioning.
- Character values and arena bounds are duplicated across client/server; they currently agree for the inspected common values.
- Scene wrappers coexist with dynamic .new() construction, which can make edits to wrapper-only properties ineffective.
- The joystick global class name does not match the name typed by MobileHUD.gd; runtime parser outcome is unverified.
- Room and simulation state are memory-only; restart loses active rooms. Network disconnect/reconnect semantics have limited client-side cleanup.
- No automated Godot or multiplayer test infrastructure was found.

## Transitions and shutdown

Server creates rooms on create_room, deletes a room only after its last socket leaves, sets lobby phase on return_lobby/disconnect, and resets match values on rematch. Client return button sends return_lobby and locally removes GameWorld immediately; GameWorld disconnects from snapshot delivery on tree exit. There is no explicit root shutdown policy, persistence, or graceful server shutdown handler in inspected source. These are code-path observations, not runtime verification.

