# Script Reference

All paths are repository-relative. Function signatures and return annotations below reflect declarations in source. Server functions are JavaScript functions; client/server are separate processes.

## Client GDScript

### scripts/core/Main.gd

Root coordinator; extends Node. Fields: network (NetworkManager), lobby (LobbyUI), game_world (GameWorld), local_id, pending_action, selected_character (defaults GameState.SWORD). _ready() adds client and connects signals. _show_lobby() removes active world, creates/wires LobbyUI once, shows it. Handlers route room creation/join, selection, ready, connection/status/messages. _start_game() hides lobby, creates GameWorld and initializes it. It listens for joined, lobby_state, match_started, return_lobby, error. Network message names are server protocol. Does not explicitly close connection or reset pending_action/local_id on disconnect. No class_name.

### scripts/networking/NetworkManager.gd

Extends Node; class_name NetworkManager. Signals connected(), disconnected(reason:String), message_received(message:Dictionary), status_changed(status:String). DEFAULT_URL is ws://127.0.0.1:8090. Holds WebSocketPeer, connection flag, URL. connect_to_server(url) strips input, uses default when empty, closes/replaces peer, attempts connection. close() closes and clears _connected. _process() polls, emits connected once per open state, parses packets and forwards Dictionary JSON, emits generic Disconnected only when previously open. send_message(type,payload={}) duplicates payload, adds type, sends JSON only if open. is_connected_to_server() checks peer state. Non-Dictionary or invalid JSON packets are silently ignored. Network lifecycle is untested.

### scripts/core/GameState.gd

Extends RefCounted; class_name GameState. Constants RED="red", BLUE="blue", SWORD="sword", BOXER="boxer". Phase enum includes BOOT, LOBBY, CHARACTER_SELECTION, WAITING_FOR_PLAYER, MATCH_START, PLAYING, PLAYER_DEAD, RESPAWNING, VICTORY, DEFEAT, RETURN_TO_LOBBY. Enum is not used as an active state machine in inspected scripts.

### scripts/core/CharacterCatalog.gd

Extends RefCounted; class_name CharacterCatalog. DATA maps sword and boxer to display name, HP, movement/dash/melee values, and draw color. get_config(character_id) returns a deep duplicate and falls back to sword for unknown IDs. Values duplicate server CHARACTERS; server controls rules. No resource loading.

### scripts/game/GameWorld.gd

Extends Node2D; class_name GameWorld. Signal leave_lobby_requested. ARENA_RECT = Rect2(-2300,-1100,4600,2200). Fields: network, local_id, player/tower dictionaries, HUD/camera, local_input Vector2, dash_down, _send_accum. initialize(net,id) connects snapshot listener and builds camera/HUD. _exit_tree() disconnects message signal. _process(delta) combines keyboard and joystick choosing vector of greater squared magnitude; sends attack/destroy immediately and input every 0.05 seconds. _draw() paints arena geometry and grid. _on_network_message() routes snapshot or logs error. _apply_snapshot() creates/updates avatars and towers, follows local player, passes data to HUD. It does not remove actor nodes absent from later snapshots; current server has fixed two players and tower set. No local gameplay authority.

### scripts/players/PlayerAvatar.gd

Extends Node2D; class_name PlayerAvatar. Snapshot state: player_id, team, character, hp/max_hp, alive, facing, attack_timer, combo_index, target_position; AbilityComponent reference. _ready() creates AbilityComponent. setup(id,data) stores id then applies snapshot with snap. apply_data() reads team/character/hp/max_hp/alive/facing_x/y/attack_timer/combo_index/x/y; optional initial snap positions immediately. _process() lerps toward target at min(1, delta*14) and redraws. _draw() renders team/character geometric body, eye, health bar and sword/boxer attack effect; visual attack range/width comes from CharacterCatalog. No animation assets, movement or hit resolution. Potential max_hp=0 display division behavior is not guarded, but server supplies positive configured values.

### scripts/towers/TowerNode.gd

Extends Node2D; class_name TowerNode. Stores ID/team/index/position/chunks/max_chunks/active/electric_radius and zap_timer. setup(data) reads identity/team/index/position then apply_data. apply_data() updates chunk/active/radius and redraws. _process() redraws every 0.18 sec; _draw() draws colored tower, chunk markers, electric radius/active arc, and randomized electric lines. Client-only illustration; server determines defense/destruction.

### scripts/camera/CameraController.gd

Extends Camera2D; class_name CameraController. Exports arena_rect (default same bounds), look_ahead Vector2(180,130), smoothing 5. target Node2D and target_facing. _ready() enables camera and disables built-in position smoothing. _process() reads PlayerAvatar facing, offsets look-ahead by facing signs unless axis magnitude <0.1, clamps center to arena minus half viewport, lerps global position using delta*smoothing. No zoom configuration or camera shake.

### scripts/combat/AbilityComponent.gd

Extends Node; class_name AbilityComponent. Signal ability_requested(slot:int), exported enabled_slots defaults 0. can_activate(slot) validates 0 <= slot < enabled_slots; request_activate(slot) returns false when invalid, otherwise emits and returns true. Added to every PlayerAvatar, but no inspected caller, listener, HUD button, or server protocol is connected. Scaffold only.

### scripts/ui/LobbyUI.gd

Extends Control; class_name LobbyUI. Signals for create/join/character/ready/start. _ready() constructs full-screen lobby controls: title/subtitle, URL and room code fields, character OptionButton, Create/Join, Ready, Start, status, room roster, message. _selected_character() returns selected item metadata. _on_character_selected() emits selection. set_status, set_message, set_room_code, update_lobby mutate controls; room display supports two players and Start reflects server can_start. Room code LineEdit max_length=8 while server generates five characters. No client-side code validation.

### scripts/ui/MobileHUD.gd

Extends CanvasLayer; class_name MobileHUD. Signals attack_pressed, dash_pressed(bool), destroy_pressed, rematch_pressed, lobby_pressed, joystick_changed(Vector2). _ready() dynamically builds HP panels, tower label, dash bar (max 100), joystick lookup/fallback, Attack/Dash/Destroy buttons, victory/rematch/lobby panel. _make_hp_panel() builds label/progress bar. _on_joystick_direction_changed() forwards direction. apply_snapshot() updates team HP bars, local dash state/charge feedback, tower label, victory panel. show_victory() displays team. _update_dash_feedback() colors button by energy and dashing. _update_tower_label() renders chunks and active marker. Typed member VirtualJoystick is not defined by the joystick script's declared class_name VirtualJoystickControl. Parse uncertainty recorded in KNOWN_ISSUES.

### scripts/ui/VirtualJoystick.gd

Extends Control; class_name VirtualJoystickControl. Signal direction_changed(dir:Vector2); exports radius 74, knob_radius 28. _ready() sets minimum size and stops mouse propagation. _gui_input() tracks one screen touch index and mouse press/drag, resets on release. _update_value() centers local position, clamps to radius, normalizes. _set_value() emits and redraws. _draw() paints base ring and knob. Input coordinate assumptions were not runtime-tested.

## Server JavaScript: server/server.js

ES module importing WebSocketServer from ws and randomUUID from crypto. Constants: port from PORT or 8090; 30 Hz tick; 15 Hz snapshot; arena bounds; 1.8 s respawn; character and tower rule objects. In-memory Maps rooms and sockets.

Core functions:
- code() generates unique five-character room code from an ambiguity-reduced alphabet.
- send(), broadcast() serialize {type,...payload}.
- makeTowers(team), makeRoom(), publicLobby(), lobbyState() build room/lobby data.
- spawnFor(), resetPlayerForMatch(), resetRoom(), startMatch() initialize two-team match and readiness.
- activeTower(), opponentOf() look up the current objective/opponent.
- damagePlayer() lowers HP, kills, starts respawn and grants killer destroyCharge.
- tryAttack(), resolveAttack() advance combo and perform facing/range hit test once per swing.
- destroyTower() consumes charge, removes a chunk, activates next tower, or sets victory/winner.
- updatePlayer() handles cooldowns, respawn, normalized input, facing, dash energy, acceleration, bounds, attack/defense updates.
- applyElectricDefense() applies periodic enemy tower damage.
- snapshot() produces public player/tower/phase fields.
- tick() updates playing rooms and broadcasts snapshots.
- joinRoom(), handle() process packet types create_room, join_room, select_character, set_ready, start_match, input, attack, destroy_tower, rematch, return_lobby.
- leave() removes disconnected player and returns remaining room to lobby.
- WebSocket connection handlers call handle/leave; setInterval starts simulation and logs bind address.

Server side effects: holds all room/player state only in RAM, binds WebSocketServer to configured port, accepts clients, and runs a process-wide interval. Review server source before changing any protocol or simulation behavior.

## Cross-script relationships

LobbyUI -> Main -> NetworkManager -> server establishes the room. GameWorld -> NetworkManager sends controls and consumes snapshots. PlayerAvatar, TowerNode, HUD and CameraController project snapshot state to visuals. CharacterCatalog provides client presentation parameters while server CHARACTERS owns rules. AbilityComponent is attached but disconnected. See [PROJECT_ARCHITECTURE.md](02%20%E2%80%94%20PROJECT_ARCHITECTURE.md) for event flow and [GAMEPLAY_SYSTEMS.md](05%20%E2%80%94%20GAMEPLAY_SYSTEMS.md) for mechanics/data details.

