# Scenes and Node Hierarchy

The scene files are thin wrappers. “Runtime use” below is based on observed source call sites, not Godot runtime tracing. In-game actors are snapshot-created with .new().

## res://main.tscn

- Purpose: configured application entry, selected by project.godot.
- Root: Main (Node), script scripts/core/Main.gd.
- Children serialized: none.
- Runtime: script adds NetworkManager and LobbyUI; later adds GameWorld.

## res://scenes/main/main.tscn

- Purpose: duplicate Main wrapper; not selected by project.godot.
- Root: Main (Node), unique_id 338809006, script scripts/core/Main.gd.
- Children serialized: none. No runtime instantiation reference found.

## res://scenes/lobby/lobby_ui.tscn

- Purpose: LobbyUI wrapper.
- Root: LobbyUI (Control), full-rect anchors, script scripts/ui/LobbyUI.gd.
- Children serialized: none. LobbyUI._ready() builds all controls.
- Runtime: Main uses LobbyUI.new(), so this wrapper is bypassed.

## res://scenes/game/game_world.tscn

- Purpose: GameWorld wrapper.
- Root: GameWorld (Node2D), script scripts/game/GameWorld.gd.
- Children serialized: none.
- Runtime: Main uses GameWorld.new(), then initialize().

## res://scenes/players/player_avatar.tscn

- Purpose: PlayerAvatar wrapper.
- Root: PlayerAvatar (Node2D), script scripts/players/PlayerAvatar.gd.
- Children serialized: none.
- Runtime: GameWorld uses PlayerAvatar.new() for new snapshot player IDs. _ready() adds AbilityComponent.

## res://scenes/towers/tower.tscn

- Purpose: TowerNode wrapper. Root node is named Tower.
- Root type: Node2D, script scripts/towers/TowerNode.gd.
- Children serialized: none.
- Runtime: GameWorld uses TowerNode.new().

## res://scenes/ui/mobile_hud.tscn

- Purpose: MobileHUD wrapper.
- Root: MobileHUD (CanvasLayer), script scripts/ui/MobileHUD.gd.
- Serialized child: VirtualJoystick (Control), script scripts/ui/VirtualJoystick.gd.
- Runtime: GameWorld uses MobileHUD.new(), so the serialized child is absent. MobileHUD.gd looks up VirtualJoystick by name and creates a fallback if none exists.

## Runtime nodes constructed in GDScript

| Runtime parent | Child or instance | Construction / behavior |
|---|---|---|
| Main | NetworkManager | Created as Main.gd field initialization, added in _ready(). |
| Main | LobbyUI | LobbyUI.new() in _show_lobby(), created once and reused. |
| Main | GameWorld | GameWorld.new() in _start_game(), recreated on match start. |
| GameWorld | CameraController | CameraController.new() in _build_world(). |
| GameWorld | MobileHUD | MobileHUD.new() in _build_world(). |
| MobileHUD's programmatic Control | VirtualJoystickControl | Existing node lookup fallback or VirtualJoystick.new(); intended fallback path. |
| GameWorld | PlayerAvatar per snapshot player ID | PlayerAvatar.new() in _apply_snapshot(). |
| PlayerAvatar | AbilityComponent | AbilityComponent.new() in _ready(). |
| GameWorld | TowerNode per snapshot tower ID | TowerNode.new() in _apply_snapshot(). |

The script declares/uses a MobileHUD variable typed VirtualJoystick, but the only class_name in the joystick script is VirtualJoystickControl. This may prevent parsing/typing; no Godot parse was available to confirm.

## Signal and node lookup inventory

- NetworkManager signals: connected, disconnected(reason), message_received(message), status_changed(status).
- LobbyUI signals: create_room(server_url, character_id), join_room(server_url, room_code, character_id), character_changed(character_id), ready_changed(is_ready), start_requested.
- GameWorld signal: leave_lobby_requested.
- MobileHUD signals: attack_pressed, dash_pressed(is_down), destroy_pressed, rematch_pressed, lobby_pressed, joystick_changed(value).
- VirtualJoystickControl: direction_changed(dir).
- AbilityComponent: ability_requested(slot).
- Explicit child lookup: MobileHUD.get_node_or_null("VirtualJoystick"). No other named-node lookup in active scripts.
- Most connections are source-script Callable/signal connections; the .tscn files serialize no signal connections.

## External resources per scene

Each .tscn references only its attached script, except mobile_hud.tscn, which also references VirtualJoystick.gd. No PackedScene children, external textures, fonts, audio, or data resources are referenced from scene files.

