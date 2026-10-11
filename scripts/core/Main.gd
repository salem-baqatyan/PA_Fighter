extends Node

var network := NetworkManager.new()
var lobby: LobbyUI
var game_world: GameWorld
var local_id := ""
var pending_action := ""
var selected_character := GameState.SWORD

func _ready() -> void:
	add_child(network)
	network.connected.connect(_on_connected)
	network.disconnected.connect(_on_disconnected)
	network.message_received.connect(_on_network_message)
	network.status_changed.connect(_on_status_changed)
	_show_lobby()

func _show_lobby() -> void:
	if game_world != null:
		game_world.queue_free()
		game_world = null
	if lobby == null:
		lobby = LobbyUI.new()
		lobby.create_room.connect(_on_create_room)
		lobby.join_room.connect(_on_join_room)
		lobby.character_changed.connect(_on_character_changed)
		lobby.ready_changed.connect(_on_ready_changed)
		lobby.start_requested.connect(func() -> void: network.send_message("start_match"))
		add_child(lobby)
	lobby.visible = true

func _on_create_room(url: String, character_id: String) -> void:
	pending_action = "create"
	selected_character = character_id
	network.connect_to_server(url)

func _on_join_room(url: String, room_code: String, character_id: String) -> void:
	pending_action = "join:%s" % room_code.strip_edges().to_upper()
	selected_character = character_id
	network.connect_to_server(url)

func _on_connected() -> void:
	if pending_action == "create":
		network.send_message("create_room", {"character": selected_character})
	elif pending_action.begins_with("join:"):
		network.send_message("join_room", {"room": pending_action.get_slice(":", 1), "character": selected_character})

func _on_disconnected(reason: String) -> void:
	_show_lobby()
	if lobby != null:
		lobby.set_status(reason)

func _on_status_changed(status: String) -> void:
	if lobby != null:
		lobby.set_status(status)

func _on_character_changed(character_id: String) -> void:
	selected_character = character_id
	if network.is_connected_to_server():
		network.send_message("select_character", {"character": selected_character})

func _on_ready_changed(is_ready: bool) -> void:
	network.send_message("set_ready", {"ready": is_ready})

func _on_network_message(message: Dictionary) -> void:
	match String(message.get("type", "")):
		"joined":
			local_id = String(message.get("player_id", ""))
			if lobby != null:
				lobby.set_room_code(String(message.get("room", "")))
				lobby.set_status("Room %s" % String(message.get("room", "")))
		"lobby_state":
			if lobby != null:
				lobby.update_lobby(message.get("players", []), bool(message.get("can_start", false)))
		"match_started":
			_start_game()
		"return_lobby":
			_show_lobby()
		"error":
			if lobby != null:
				lobby.set_message(String(message.get("message", "Unknown error")))

func _start_game() -> void:
	if lobby != null:
		lobby.visible = false
	if game_world != null:
		game_world.queue_free()
	game_world = GameWorld.new()
	add_child(game_world)
	game_world.initialize(network, local_id)
	game_world.leave_lobby_requested.connect(_show_lobby)
